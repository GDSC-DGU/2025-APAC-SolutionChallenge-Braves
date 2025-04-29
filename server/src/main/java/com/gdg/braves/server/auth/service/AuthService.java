package com.gdg.braves.server.auth.service;

import com.gdg.braves.server.auth.dto.AuthResponseDto;
import com.gdg.braves.server.auth.dto.GoogleUserInfo;
import com.gdg.braves.server.config.JwtProvider;
import com.gdg.braves.server.exception.CustomException;
import com.gdg.braves.server.exception.ErrorCode;
import com.gdg.braves.server.user.entity.User;
import com.gdg.braves.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;
    private final WebClient webClient; // WebClient 주입

    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private String googleClientId;
    @Value("${spring.security.oauth2.client.registration.google.client-secret}")
    private String googleClientSecret;
    @Value("${spring.security.oauth2.client.registration.google.redirect-uri}")
    private String googleRedirectUri;
    @Value("${spring.security.oauth2.client.provider.google.token-uri}")
    private String googleTokenUri;
    @Value("${spring.security.oauth2.client.provider.google.user-info-uri}")
    private String googleUserInfoUri;

    /**
     * 구글 로그인 시 인가 코드를 사용하여 사용자 인증을 수행합니다.
     *
     * @param authorizationCode 구글에서 발급받은 인가 코드
     * @return AuthResponseDto
     */
    public AuthResponseDto loginWithGoogle(String authorizationCode) {
        log.info("[loginWithGoogle] 인가 코드: {}", authorizationCode);

        // 1. 인가 코드로 액세스 토큰 요청
        Mono<String> accessTokenMono = webClient.post()
                .uri(googleTokenUri)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE)
                .body(BodyInserters.fromFormData(generateTokenRequest(authorizationCode)))
                .retrieve()
                .bodyToMono(Map.class)
                .map(response -> (String) response.get("access_token"))
                .doOnNext(accessToken -> log.info("[loginWithGoogle] 액세스 토큰: {}", accessToken));

        String accessToken = accessTokenMono.block(); // 동기적으로 액세스 토큰 획득

        if (accessToken == null) {
            log.error("[loginWithGoogle] 구글 액세스 토큰 획득 실패");
            throw new CustomException(ErrorCode.GOOGLE_ACCESS_TOKEN_FAILED);
        }

        // 2. 액세스 토큰으로 구글 사용자 정보 요청
        GoogleUserInfo googleUser = getGoogleUserInfo(accessToken);

        // 3. DB에 사용자 조회 or 신규 저장
        User user = userRepository.findBySocialId(googleUser.getSub())
                .orElseGet(() -> userRepository.save(User.builder()
                        .socialId(googleUser.getSub())
                        .email(googleUser.getEmail())
                        .username(googleUser.getName())
                        .profileImage(googleUser.getPicture())
                        .role("USER")
                        .build()));

        // 4. JWT 토큰 생성
        String token = jwtProvider.createToken(user.getId(), user.getEmail());

        // 5. 응답 DTO
        return AuthResponseDto.builder()
                .accessToken(token)
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .profileImage(user.getProfileImage())
                .build();
    }

    /**
     * 모바일에서 구글 로그인 시 ID 토큰을 사용하여 사용자 인증을 수행합니다.
     *
     * @param idToken 구글에서 발급받은 ID 토큰
     * @return AuthResponseDto
     */
    public AuthResponseDto loginWithGoogleMobile(String idToken) {
        log.info("[loginWithGoogleMobile] ID 토큰: {}", idToken);

        // 1. ID 토큰 검증 (Google API 사용)
        String googleTokenInfoUrl = "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken;
        Mono<Map> tokenInfoMono = webClient.get()
                .uri(googleTokenInfoUrl)
                .retrieve()
                .bodyToMono(Map.class);

        Map tokenInfo = tokenInfoMono.block();

        if (tokenInfo == null || !googleClientId.equals(tokenInfo.get("aud"))) {
            log.error("[loginWithGoogleMobile] 유효하지 않은 구글 ID 토큰입니다.");
            throw new CustomException(ErrorCode.INVALID_GOOGLE_ID_TOKEN);
        }

        String socialId = (String) tokenInfo.get("sub");
        String email = (String) tokenInfo.get("email");
        String name = (String) tokenInfo.get("name");
        String picture = (String) tokenInfo.get("picture");

        // 2. DB에 사용자 조회 or 신규 저장
        User user = userRepository.findBySocialId(socialId)
                .orElseGet(() -> userRepository.save(User.builder()
                        .socialId(socialId)
                        .email(email)
                        .username(name)
                        .profileImage(picture)
                        .role("USER")
                        .build()));

        // 3. JWT 토큰 생성
        String token = jwtProvider.createToken(user.getId(), user.getRole());

        // 4. 응답 DTO
        return AuthResponseDto.builder()
                .accessToken(token)
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .profileImage(user.getProfileImage())
                .build();
    }

    private GoogleUserInfo getGoogleUserInfo(String accessToken) {
        Mono<GoogleUserInfo> googleUserInfoMono = webClient.get()
                .uri(googleUserInfoUri)
                .headers(header -> header.setBearerAuth(accessToken))
                .retrieve()
                .onStatus(HttpStatusCode::isError, response -> {
                    log.error("[getGoogleUserInfo] 구글 사용자 정보 획득 실패: {} {}", response.statusCode(), response.bodyToMono(String.class).block());
                    return Mono.error(new CustomException(ErrorCode.GOOGLE_USER_INFO_FAILED));
                })
                .bodyToMono(GoogleUserInfo.class);

        return googleUserInfoMono.block(); // 동기적으로 호출
    }

    private MultiValueMap<String, String> generateTokenRequest(String authorizationCode) {
        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("grant_type", "authorization_code");
        formData.add("client_id", googleClientId);
        formData.add("client_secret", googleClientSecret);
        formData.add("redirect_uri", googleRedirectUri);
        formData.add("code", authorizationCode);
        return formData;
    }
}
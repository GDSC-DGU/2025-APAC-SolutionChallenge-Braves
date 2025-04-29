package com.gdg.braves.server.auth.service;

import com.gdg.braves.server.auth.dto.AuthResponseDto;
import com.gdg.braves.server.auth.dto.GoogleUserInfo;
import com.gdg.braves.server.config.JwtProvider;
import com.gdg.braves.server.user.entity.User;
import com.gdg.braves.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
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
            log.error("[loginWithGoogle] 액세스 토큰 획득 실패");
            // 예외 처리 필요 (예: CustomException 던지기)
            throw new RuntimeException("Failed to get Google access token");
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
        String token = jwtProvider.createToken(user.getId(), user.getRole());

        // 5. 응답 DTO
        return AuthResponseDto.builder()
                .accessToken(token)
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .profileImage(user.getProfileImage())
                .build();
    }

    private GoogleUserInfo getGoogleUserInfo(String accessToken) {
        return webClient.get()
                .uri(googleUserInfoUri)
                .headers(header -> header.setBearerAuth(accessToken))
                .retrieve()
                .bodyToMono(GoogleUserInfo.class)
                .block(); // 동기적으로 호출
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
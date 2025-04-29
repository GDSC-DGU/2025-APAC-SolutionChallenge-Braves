package com.gdg.braves.server.config;


import com.gdg.braves.server.user.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Date;

@Service
public class JwtProvider {

    @Value("${jwt.secret}")
    private String secretKey;

    private final long validityInMilliseconds = 3600000; // 1 hour

    // 토큰 생성
    public String createToken(Long id, String username) {
        Claims claims = Jwts.claims().setSubject(username);
        Date now = new Date();
        Date validity = new Date(now.getTime() + validityInMilliseconds);

        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(validity)
                .signWith(SignatureAlgorithm.HS256, secretKey)
                .compact();
    }

    // 토큰에서 사용자 이름 추출
    public String getUsernameFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    // 토큰 유효성 검증
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // 토큰에서 Claims 추출
    private Claims parseClaims(String token) {
        return Jwts.parser()
                .setSigningKey(secretKey)
                .parseClaimsJws(token)
                .getBody();
    }

    // 인증 객체 생성
    public Authentication getAuthentication(String username) {
        // User 객체 생성 시, 필수 필드들을 채워야 합니다
        // 필수 필드들을 적절히 설정합니다.
        User userDetails = User.builder()
                .id(null) // id는 null로 두고, DB에서 자동 생성되도록
                .socialId("socialId") // socialId는 실제 값이 필요합니다
                .email(username) // email에 username 사용
                .username(username) // username을 email로 사용
                .profileImage("") // profileImage URL 필요
                .role("USER") // 기본 역할을 USER로 설정
                .createdAt(LocalDateTime.now()) // 생성일은 현재 시간
                .updatedAt(LocalDateTime.now()) // 수정일은 현재 시간
                .build();

        return new UsernamePasswordAuthenticationToken(userDetails, "", userDetails.getAuthorities());
    }

    // 요청에서 토큰 추출
    public String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);  // "Bearer " 제외한 토큰만 반환
        }
        return null;
    }
}
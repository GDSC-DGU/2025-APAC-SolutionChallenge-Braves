package com.gdg.braves.server.config;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;


@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtProvider jwtProvider;
    private final JwtTokenFilter jwtTokenFilter;

    public SecurityConfig(JwtProvider jwtProvider, JwtTokenFilter jwtTokenFilter) {
        this.jwtProvider = jwtProvider;
        this.jwtTokenFilter = jwtTokenFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)  // CSRF 보호 비활성화
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))  // 세션 사용 안 함
                .addFilterBefore(jwtTokenFilter, UsernamePasswordAuthenticationFilter.class)  // JWT 필터 추가
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/signin", "/api/auth/signup", "/api/auth/google/callback").permitAll()  // 로그인, 회원가입은 인증 없이 접근 가능
                        .requestMatchers("/api/**").authenticated()  // 모든 `/api/**` 요청은 인증 필요
                        .anyRequest().denyAll()  // 나머지 요청은 전부 접근 제한
                )
                .build();
    }

    // AuthenticationManager는 AuthenticationManagerBuilder를 통해 설정
    @Bean
    public AuthenticationManager authenticationManager(HttpSecurity http) throws Exception {
        AuthenticationManagerBuilder authenticationManagerBuilder =
                http.getSharedObject(AuthenticationManagerBuilder.class);
        return authenticationManagerBuilder.build();
    }
}

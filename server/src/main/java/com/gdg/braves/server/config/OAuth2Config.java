//package com.gdg.braves.server.config;
//
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.security.config.annotation.web.builders.HttpSecurity;
//import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
//import org.springframework.security.oauth2.client.endpoint.OAuth2AccessTokenResponseClient;
//import org.springframework.security.oauth2.client.endpoint.OAuth2AuthorizationCodeGrantRequest;
//import org.springframework.security.oauth2.client.registration.ClientRegistration;
//import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
//import org.springframework.security.oauth2.client.registration.InMemoryClientRegistrationRepository;
//import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
//import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
//import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestResolver;
//import org.springframework.security.oauth2.client.web.OAuth2LoginAuthenticationFilter;
//
//@Configuration
//@EnableWebSecurity
//public class OAuth2Config {
//
//    @Bean
//    public ClientRegistrationRepository clientRegistrationRepository() {
//        return new InMemoryClientRegistrationRepository(this.googleClientRegistration());
//    }
//
//    private ClientRegistration googleClientRegistration() {
//        return ClientRegistration
//                .withRegistrationId("google")
//                .clientId("YOUR_GOOGLE_CLIENT_ID")
//                .clientSecret("YOUR_GOOGLE_CLIENT_SECRET")
//                .scope("openid", "profile", "email")
//                .redirectUri("{baseUrl}/auth/callback")
//                .authorizationUri("https://accounts.google.com/o/oauth2/auth")
//                .tokenUri("https://oauth2.googleapis.com/token")
//                .userInfoUri("https://www.googleapis.com/oauth2/v3/userinfo")
//                .userNameAttributeName("sub")
//                .clientName("Google")
//                .build();
//    }
//
//    @Bean
//    public OAuth2LoginAuthenticationFilter oAuth2LoginAuthenticationFilter(ClientRegistrationRepository clientRegistrationRepository) {
//        OAuth2LoginAuthenticationFilter filter = new OAuth2LoginAuthenticationFilter(clientRegistrationRepository);
//        filter.setAuthorizationRequestResolver(new DefaultAuthorizationRequestResolver());
//        return filter;
//    }
//
//    @Bean
//    public OAuth2AuthorizationRequestResolver defaultAuthorizationRequestResolver(ClientRegistrationRepository clientRegistrationRepository) {
//        return new DefaultAuthorizationRequestResolver(clientRegistrationRepository);
//    }
//
//    @Bean
//    public OAuth2LoginAuthenticationFilter oauth2LoginAuthenticationFilter(
//            ClientRegistrationRepository clientRegistrationRepository,
//            OAuth2AuthorizationRequestResolver authorizationRequestResolver) {
//        OAuth2LoginAuthenticationFilter filter = new OAuth2LoginAuthenticationFilter(
//                clientRegistrationRepository, authorizationRequestResolver);
//        return filter;
//    }
//
//    @Configuration
//    public class SecurityConfig extends WebSecurityConfigurerAdapter {
//
//        @Override
//        protected void configure(HttpSecurity http) throws Exception {
//            http
//                    .csrf().disable()
//                    .authorizeRequests()
//                    .antMatchers("/auth/login", "/auth/callback", "/auth/logout").permitAll() // 로그인, 콜백, 로그아웃은 누구나 접근 가능
//                    .antMatchers(HttpMethod.GET, "/user/**").hasRole("USER") // /user/** 경로는 USER 권한만
//                    .anyRequest().authenticated()  // 나머지는 인증된 사용자만 접근
//                    .and()
//                    .oauth2Login()
//                    .clientRegistrationRepository(clientRegistrationRepository())  // 구글 OAuth2 설정
//                    .authorizationEndpoint()
//                    .baseUri("/oauth2/authorization")  // 기본 OAuth2 authorization endpoint
//                    .and()
//                    .tokenEndpoint()
//                    .accessTokenResponseClient(oAuth2AccessTokenResponseClient()) // Access Token 응답을 처리하는 클라이언트
//                    .and()
//                    .userInfoEndpoint()
//                    .userService(oAuth2UserService());  // OAuth2 UserInfo 서비스
//        }
//
//        // Access Token 응답 처리기
//        private OAuth2AccessTokenResponseClient<OAuth2AuthorizationCodeGrantRequest> oAuth2AccessTokenResponseClient() {
//            return new DefaultOAuth2AccessTokenResponseClient();
//        }
//
//        // OAuth2 사용자 정보 가져오는 서비스
//        private OAuth2UserService oAuth2UserService() {
//            return new DefaultOAuth2UserService();
//        }
//    }
//}
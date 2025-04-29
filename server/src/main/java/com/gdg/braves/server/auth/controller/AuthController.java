package com.gdg.braves.server.auth.controller;

import com.gdg.braves.server.auth.dto.AuthRequestDto;
import com.gdg.braves.server.auth.dto.AuthResponseDto;
import com.gdg.braves.server.auth.service.AuthService;
import com.gdg.braves.server.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@Slf4j
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signin")
    public ApiResponse<AuthResponseDto> signin(@RequestBody AuthRequestDto request) {
        AuthResponseDto response = authService.loginWithGoogle(request.getAccessToken());
        return ApiResponse.success(response);
    }

    @GetMapping("/google/callback")
    public ApiResponse<AuthResponseDto> googleCallback(@RequestParam("code") String code) {
        log.info("[Google Callback] 인가 코드: {}", code);
        AuthResponseDto response = authService.loginWithGoogle(code); // AuthService에서 인가 코드로 처리
        return ApiResponse.success(response);
    }

    @PostMapping("/google/mobile")
    public ApiResponse<AuthResponseDto> googleMobileLogin(@RequestBody Map<String, String> payload) {
        String idToken = payload.get("idToken"); // 앱에서 전달받은 ID 토큰
        if (idToken == null || idToken.isEmpty()) {
            return ApiResponse.fail(400, "ID 토큰이 없습니다.");
        }
        AuthResponseDto response = authService.loginWithGoogleMobile(idToken); // 새로운 서비스 메서드
        return ApiResponse.success(response);
    }

    @GetMapping("/test")
    public ApiResponse<String> test() {
        return ApiResponse.success("test");
    }
}
package com.gdg.braves.server.auth.dto;


import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResponseDto {
    private String accessToken;
    private Long userId;
    private String email;
    private String username;
    private String profileImage;
}
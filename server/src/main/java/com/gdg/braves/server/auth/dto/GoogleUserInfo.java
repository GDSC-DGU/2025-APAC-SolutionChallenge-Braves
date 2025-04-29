package com.gdg.braves.server.auth.dto;

import lombok.Getter;

@Getter
public class GoogleUserInfo {
    private String sub;        // 구글 고유 ID
    private String email;
    private String name;       // 사용자 이름
    private String picture;    // 프로필 사진 URL
}
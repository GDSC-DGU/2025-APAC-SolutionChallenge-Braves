package com.gdg.braves.server.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Collections;

@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(columnNames = "socialId"),
        @UniqueConstraint(columnNames = "email")
})
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String socialId;  // 구글 OAuth2 sub

    @Column(nullable = false, length = 255)
    private String email;  // 구글 이메일

    @Column(nullable = false, length = 50)
    private String username;  // 구글 프로필 이름 (닉네임)

    @Column(length = 500)
    private String profileImage;  // 프로필 사진 URL

    @Column(nullable = false, length = 20)
    private String role = "USER";  // 기본 권한

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // UserDetails 구현

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // 'USER'와 같은 기본 권한을 부여
        return Collections.singletonList(() -> "ROLE_" + this.role);
    }

    @Override
    public String getPassword() {
        // 구글 로그인에서는 비밀번호가 없으므로 빈 문자열을 반환
        return "";
    }

    @Override
    public String getUsername() {
        return this.email;  // 구글 이메일을 username으로 사용
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;  // 계정 만료 여부
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;  // 계정 잠금 여부
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;  // 자격 증명 만료 여부
    }

    @Override
    public boolean isEnabled() {
        return true;  // 활성화 여부
    }
}
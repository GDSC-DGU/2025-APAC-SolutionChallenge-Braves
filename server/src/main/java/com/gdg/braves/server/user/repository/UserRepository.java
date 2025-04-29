package com.gdg.braves.server.user.repository;

import com.gdg.braves.server.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    // 소셜 ID로 사용자 조회
    Optional<User> findBySocialId(String socialId);
}
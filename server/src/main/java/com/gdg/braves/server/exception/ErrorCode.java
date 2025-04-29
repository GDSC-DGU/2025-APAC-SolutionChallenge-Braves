package com.gdg.braves.server.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {

    // 공통 에러
    INVALID_INPUT_VALUE(400, "잘못된 입력입니다.", HttpStatus.BAD_REQUEST),
    METHOD_NOT_ALLOWED(405, "허용되지 않은 HTTP 메서드입니다.", HttpStatus.METHOD_NOT_ALLOWED),
    INTERNAL_SERVER_ERROR(500, "서버 오류입니다.", HttpStatus.INTERNAL_SERVER_ERROR),

    // 인증 관련 에러
    INVALID_TOKEN(3000, "유효하지 않은 토큰입니다.", HttpStatus.UNAUTHORIZED),
    EXPIRED_TOKEN(3001, "만료된 토큰입니다.", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED_ACCESS(3002, "인증이 필요합니다.", HttpStatus.UNAUTHORIZED),

    // 사용자 관련 에러
    USER_NOT_FOUND(4000, "존재하지 않는 사용자입니다.", HttpStatus.NOT_FOUND),
    DUPLICATE_NICKNAME(4001, "중복하는 닉네임입니다.", HttpStatus.CONFLICT),

    // 구글 OAuth 관련 에러
    GOOGLE_LOGIN_FAILED(5000, "구글 로그인에 실패했습니다.", HttpStatus.UNAUTHORIZED);

    private final int code;         // 비즈니스 에러 코드 (우리 서버 내부 규칙)
    private final String message;   // 에러 메시지
    private final HttpStatus status; // HTTP 상태 코드

    ErrorCode(int code, String message, HttpStatus status) {
        this.code = code;
        this.message = message;
        this.status = status;
    }
}

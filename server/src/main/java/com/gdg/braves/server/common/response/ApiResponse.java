package com.gdg.braves.server.common.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class ApiResponse<T> {
    private int code;         // 상태 코드 (예: 200, 400, 500 등)
    private boolean success;  // 성공 여부
    private String msg;       // 메시지
    private T data;           // 실제 데이터 (없을 수도 있음)

    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .code(200)
                .success(true)
                .msg("요청에 성공했습니다.")
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .code(200)
                .success(true)
                .msg(message)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> fail(int code, String message) {
        return ApiResponse.<T>builder()
                .code(code)
                .success(false)
                .msg(message)
                .data(null)
                .build();
    }
}

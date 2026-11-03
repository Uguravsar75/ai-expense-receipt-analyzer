package com.yapayzeka.backend.exception;

/**
 * Kullanıcı kimlik doğrulaması başarısız olduğunda fırlatılır
 */
public class UnauthorizedException extends RuntimeException {
    public UnauthorizedException(String message) {
        super(message);
    }

    public UnauthorizedException(String message, Throwable cause) {
        super(message, cause);
    }
}

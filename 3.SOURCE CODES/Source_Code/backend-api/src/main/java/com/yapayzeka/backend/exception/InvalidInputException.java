package com.yapayzeka.backend.exception;

/**
 * Giriş veya çıkış verisi geçersiz olduğunda fırlatılır
 */
public class InvalidInputException extends RuntimeException {
    public InvalidInputException(String message) {
        super(message);
    }

    public InvalidInputException(String message, Throwable cause) {
        super(message, cause);
    }
}

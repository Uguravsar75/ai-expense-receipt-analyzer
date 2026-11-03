package com.yapayzeka.backend.exception;

/**
 * Kullanıcı bulunamadığında fırlatılır
 */
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }

    public UserNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}

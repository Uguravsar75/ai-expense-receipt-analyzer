package com.yapayzeka.backend.exception;

/**
 * AI Service çağrısı başarısız olduğunda fırlatılır
 */
public class AIServiceException extends RuntimeException {
    public AIServiceException(String message) {
        super(message);
    }

    public AIServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}

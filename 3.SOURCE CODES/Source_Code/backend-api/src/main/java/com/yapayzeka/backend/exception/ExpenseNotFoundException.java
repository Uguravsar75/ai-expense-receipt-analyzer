package com.yapayzeka.backend.exception;

/**
 * Harcama bulunamadığında fırlatılır
 */
public class ExpenseNotFoundException extends RuntimeException {
    public ExpenseNotFoundException(String message) {
        super(message);
    }

    public ExpenseNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}

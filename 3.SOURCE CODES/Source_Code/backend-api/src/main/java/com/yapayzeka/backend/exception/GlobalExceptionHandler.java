package com.yapayzeka.backend.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Global exception handler - tüm exception'ları handle et
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * Yetkisiz erişim (401)
     */
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<?> handleUnauthorized(
            UnauthorizedException ex,
            WebRequest request) {
        log.warn("Unauthorized access: {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.UNAUTHORIZED.value());
        response.put("error", "Unauthorized");
        response.put("message", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

    /**
     * Kaynak bulunamadı (404)
     */
    @ExceptionHandler({ResourceNotFoundException.class, 
                      UserNotFoundException.class, 
                      ExpenseNotFoundException.class})
    public ResponseEntity<?> handleNotFound(
            RuntimeException ex,
            WebRequest request) {
        log.warn("Resource not found: {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.NOT_FOUND.value());
        response.put("error", "Not Found");
        response.put("message", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * Geçersiz giriş verisi (400)
     */
    @ExceptionHandler({InvalidInputException.class, 
                      IllegalArgumentException.class})
    public ResponseEntity<?> handleBadRequest(
            RuntimeException ex,
            WebRequest request) {
        log.warn("Invalid input: {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.BAD_REQUEST.value());
        response.put("error", "Bad Request");
        response.put("message", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * Validation error (400)
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidationErrors(
            MethodArgumentNotValidException ex,
            WebRequest request) {
        log.warn("Validation error: {}", ex.getMessage());
        
        Map<String, String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                        error -> error.getField(),
                        error -> error.getDefaultMessage()
                ));
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.BAD_REQUEST.value());
        response.put("error", "Validation Failed");
        response.put("fieldErrors", errors);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * AI Service hatası (503)
     */
    @ExceptionHandler(AIServiceException.class)
    public ResponseEntity<?> handleAIServiceError(
            AIServiceException ex,
            WebRequest request) {
        log.error("AI Service error: {}", ex.getMessage(), ex);
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.SERVICE_UNAVAILABLE.value());
        response.put("error", "AI Service Unavailable");
        response.put("message", "Yapay zeka servisi şu anda kullanılamıyor");
        
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response);
    }

    /**
     * Genel hata (500)
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleGlobalException(
            Exception ex,
            WebRequest request) {
        log.error("Unexpected error: ", ex);
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        response.put("error", "Internal Server Error");
        response.put("message", "Bir hata oluştu, lütfen tekrar deneyin");
        
        // Development ortamında hata detayları göster
        if (isDevEnvironment()) {
            response.put("exception", ex.getClass().getName());
            response.put("details", ex.getMessage());
        }
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }

    private boolean isDevEnvironment() {
        String profile = System.getenv("SPRING_PROFILES_ACTIVE");
        return profile == null || profile.contains("dev");
    }
}

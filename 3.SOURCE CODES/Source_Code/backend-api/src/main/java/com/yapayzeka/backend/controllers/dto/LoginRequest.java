package com.yapayzeka.backend.controllers.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {
    
    @NotBlank(message = "Email boş olamaz")
    @Email(message = "Geçerli bir email adresi gir")
    private String email;
    
    @NotBlank(message = "Şifre boş olamaz")
    @Size(min = 6, max = 100, message = "Şifre 6-100 karakter olmalı")
    private String password;
}

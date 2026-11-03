package com.yapayzeka.backend.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    // Email doğrulama
    @Column(nullable = false, columnDefinition = "boolean default false")
    private boolean emailVerified = false;

    @Column(unique = true)
    private String verificationToken;

    // Şifre sıfırlama
    @Column(unique = true)
    private String resetToken;

    private LocalDateTime resetTokenExpiry;
}

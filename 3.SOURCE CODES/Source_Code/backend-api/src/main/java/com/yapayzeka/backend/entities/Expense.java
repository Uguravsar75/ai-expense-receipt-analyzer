package com.yapayzeka.backend.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "expense")
@Getter
@Setter
public class Expense {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(nullable = false)
    private Double amount;

    @Column(nullable = false)
    private String category;

    private String predictedCategory;

    // null = kullanıcı henüz değerlendirmedi, true = AI doğru, false = kullanıcı düzeltti
    private Boolean aiAccepted;

    private String description;

    // =========================
    // 🟣 TARİH ALANI (KRİTİK)
    // =========================
    @Column(
        name = "created_at",
        nullable = false,
        updatable = false,
        columnDefinition = "timestamp default now()"
    )
    private LocalDateTime createdAt;

    // =========================
    // USER
    // =========================
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // =========================
    // AUTO SET
    // =========================
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}

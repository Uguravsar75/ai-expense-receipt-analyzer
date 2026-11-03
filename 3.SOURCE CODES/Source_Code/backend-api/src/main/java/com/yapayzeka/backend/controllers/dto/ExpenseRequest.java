package com.yapayzeka.backend.controllers.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ExpenseRequest {

    @NotNull(message = "Tutar boş olamaz")
    @DecimalMin(value = "0.01", message = "Tutar 0'dan büyük olmalı")
    @DecimalMax(value = "10000000", message = "Tutar çok büyük")
    private Double amount;

    @NotBlank(message = "Kategori boş olamaz")
    @Size(min = 2, max = 50, message = "Kategori 2-50 karakter olmalı")
    private String category;

    @Size(max = 500, message = "Açıklama en fazla 500 karakter olmalı")
    private String description;
}

package com.yapayzeka.backend.controllers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CategoryStatResponse {
    private String category;
    private Double total;
    private Double percentage;
}

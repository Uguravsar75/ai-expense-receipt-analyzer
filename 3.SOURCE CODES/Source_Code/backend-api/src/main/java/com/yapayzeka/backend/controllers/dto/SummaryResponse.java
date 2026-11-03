package com.yapayzeka.backend.controllers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class SummaryResponse {
    private Double totalAmount;
    private Double averageDaily;
    private String topCategory;
}

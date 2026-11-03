package com.yapayzeka.backend.controllers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AnalyzeRequest {
    private Double totalAmount;
    private Double averageDaily;
    private String topCategory;
    private List<CategoryStatResponse> categoryStats;
}

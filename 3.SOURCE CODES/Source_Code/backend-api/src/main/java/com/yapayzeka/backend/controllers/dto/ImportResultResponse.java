package com.yapayzeka.backend.controllers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ImportResultResponse {
    private int totalRows;
    private int imported;
    private int skipped;
    private List<String> errors;
    private List<ImportedExpenseDto> expenses;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ImportedExpenseDto {
        private Double amount;
        private String description;
        private String predictedCategory;
        private String finalCategory;
        private String date; // Gemini'den gelen fiş tarihi (YYYY-MM-DD), null olabilir
    }
}

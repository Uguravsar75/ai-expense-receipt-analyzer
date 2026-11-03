package com.yapayzeka.backend.controllers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DailyStatResponse {
    private String date;   // "2025-01-20"
    private Double total;  // o günkü toplam
}

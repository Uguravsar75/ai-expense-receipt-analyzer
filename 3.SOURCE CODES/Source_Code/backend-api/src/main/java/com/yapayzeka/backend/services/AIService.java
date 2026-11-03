package com.yapayzeka.backend.services;

import com.yapayzeka.backend.controllers.dto.AnalyzeRequest;
import com.yapayzeka.backend.controllers.dto.AnalyzeResponse;
import com.yapayzeka.backend.controllers.dto.CategoryStatResponse;

import java.util.List;
import java.util.Map;

public interface AIService {

    String predictCategory(String description);

    AnalyzeResponse analyze(AnalyzeRequest request);

    List<Map<String, Object>> detectAnomalies(List<Double> amounts);

    Map<String, Object> getBudgetAdvice(double totalAmount, double averageDaily,
                                        List<CategoryStatResponse> categoryStats);

    Map<String, Object> getForecast(List<Double> dailyAmounts, int forecastDays);

    Map<String, Object> fullAnalyze(double totalAmount, double averageDaily,
                                    String topCategory,
                                    List<CategoryStatResponse> categoryStats,
                                    List<Double> amounts,
                                    List<Double> dailyAmounts);

    Map<String, Object> analyzeReceiptImage(byte[] imageBytes, String originalFilename);

    /** Son 3 aya göre kategori bazlı akıllı bütçe tahmini */
    Map<String, Object> getSmartBudget(List<Map<String, Object>> monthlyStats);

    boolean isGeminiAvailable();
}

package com.yapayzeka.backend.services.impl;

import com.yapayzeka.backend.controllers.dto.AnalyzeRequest;
import com.yapayzeka.backend.controllers.dto.AnalyzeResponse;
import com.yapayzeka.backend.controllers.dto.CategoryStatResponse;
import com.yapayzeka.backend.exception.AIServiceException;
import com.yapayzeka.backend.services.AIService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import org.springframework.core.io.ByteArrayResource;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class AIServiceImpl implements AIService {

    private final RestTemplateBuilder restTemplateBuilder;

    @Value("${ai.service.url:http://localhost:8000}")
    private String aiServiceUrl;

    @Value("${ai.service.timeout:5000}")
    private int aiServiceTimeout;

    private RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(aiServiceTimeout);
        factory.setReadTimeout(aiServiceTimeout);
        return restTemplateBuilder.requestFactory(() -> factory).build();
    }

    private <T> ResponseEntity<T> post(String path, Object body, Class<T> responseType) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Object> entity = new HttpEntity<>(body, headers);
        return restTemplate().postForEntity(aiServiceUrl + path, entity, responseType);
    }

    private static final Map<String, String> CATEGORY_MAP = Map.ofEntries(
            Map.entry("market", "Market"),
            Map.entry("yeme ve icme", "Yeme & İçme"),
            Map.entry("yeme & içme", "Yeme & İçme"),
            Map.entry("faturalar", "Faturalar"),
            Map.entry("ulasim", "Ulaşım"),
            Map.entry("ulaşım", "Ulaşım"),
            Map.entry("kira ve ev", "Kira & Ev"),
            Map.entry("kira & ev", "Kira & Ev"),
            Map.entry("saglik", "Sağlık"),
            Map.entry("sağlık", "Sağlık"),
            Map.entry("eglence", "Eğlence"),
            Map.entry("eğlence", "Eğlence"),
            Map.entry("giyim", "Giyim"),
            Map.entry("egitim", "Eğitim"),
            Map.entry("eğitim", "Eğitim"),
            Map.entry("diger", "Diğer"),
            Map.entry("diğer", "Diğer"),
            Map.entry("other", "Diğer")
    );

    private String normalizeAiCategory(String category) {
        if (category == null || category.isBlank() || "unknown".equalsIgnoreCase(category.trim())) {
            return "unknown";
        }
        String key = category.trim().toLowerCase(Locale.ROOT);
        return CATEGORY_MAP.getOrDefault(key, category.trim());
    }

    // =========================
    // KATEGORİ TAHMİNİ
    // =========================
    @Override
    public String predictCategory(String description) {
        if (description == null || description.isBlank()) return "unknown";

        try {
            Map<String, String> body = Map.of("text", description);
            ResponseEntity<Map> response = post("/predict", body, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Object cat = response.getBody().get("category");
                if (cat != null && !cat.toString().isBlank()) {
                    String normalized = normalizeAiCategory(cat.toString());
                    log.info("AI kategori tahmini: '{}' → {}", description, normalized);
                    return normalized;
                }
            }
        } catch (RestClientException e) {
            log.error("AI servise bağlanılamadı (predict): {}", e.getMessage());
            throw new AIServiceException("AI servise bağlanılamadı: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("AI predict beklenmedik hata", e);
        }
        return "unknown";
    }

    // =========================
    // ANALİZ & YORUM (eski)
    // =========================
    @Override
    public AnalyzeResponse analyze(AnalyzeRequest request) {
        try {
            ResponseEntity<AnalyzeResponse> response = post("/analyze", request, AnalyzeResponse.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            }
        } catch (Exception e) {
            log.error("AI analyze hatası: {}", e.getMessage());
        }
        return new AnalyzeResponse(List.of("AI analizi şu anda kullanılamıyor."));
    }

    // =========================
    // ANOMALİ TESPİTİ
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> detectAnomalies(List<Double> amounts) {
        if (amounts == null || amounts.size() < 5) {
            log.debug("Anomali için yeterli veri yok ({})", amounts == null ? 0 : amounts.size());
            return List.of();
        }

        try {
            Map<String, Object> body = Map.of("amounts", amounts, "contamination", 0.1);
            ResponseEntity<Map> response = post("/anomaly", body, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                List<Map<String, Object>> anomalies =
                        (List<Map<String, Object>>) response.getBody().get("anomalies");
                log.info("AI anomali tespiti: {} anomali bulundu", anomalies == null ? 0 : anomalies.size());
                return anomalies != null ? anomalies : List.of();
            }
        } catch (RestClientException e) {
            log.warn("AI anomaly servisi ulaşılamadı: {}", e.getMessage());
        } catch (Exception e) {
            log.error("AI anomaly beklenmedik hata", e);
        }
        return List.of();
    }

    // =========================
    // BÜTÇE DANIŞMANLIĞI
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public Map<String, Object> getBudgetAdvice(double totalAmount, double averageDaily,
                                               List<CategoryStatResponse> categoryStats) {
        try {
            List<Map<String, Object>> catList = categoryStats.stream()
                    .map(c -> Map.<String, Object>of(
                            "category", c.getCategory(),
                            "total", c.getTotal(),
                            "percentage", c.getPercentage()
                    ))
                    .toList();

            Map<String, Object> body = new HashMap<>();
            body.put("totalAmount", totalAmount);
            body.put("averageDaily", averageDaily);
            body.put("categoryStats", catList);

            ResponseEntity<Map> response = post("/budget", body, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("AI bütçe tavsiyesi alındı: risk={}", response.getBody().get("risk_level"));
                return (Map<String, Object>) response.getBody();
            }
        } catch (RestClientException e) {
            log.warn("AI budget servisi ulaşılamadı: {}", e.getMessage());
        } catch (Exception e) {
            log.error("AI budget beklenmedik hata", e);
        }
        return fallbackBudget(averageDaily, totalAmount);
    }

    // =========================
    // TAHMİNLEME
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public Map<String, Object> getForecast(List<Double> dailyAmounts, int forecastDays) {
        if (dailyAmounts == null || dailyAmounts.size() < 3) {
            return Map.of("forecast", List.of(), "trend", "insufficient_data",
                    "predicted_monthly", 0.0, "method", "none");
        }

        try {
            Map<String, Object> body = Map.of(
                    "dailyAmounts", dailyAmounts,
                    "forecastDays", forecastDays
            );

            ResponseEntity<Map> response = post("/forecast", body, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("AI tahminleme tamamlandı: method={}", response.getBody().get("method"));
                return (Map<String, Object>) response.getBody();
            }
        } catch (RestClientException e) {
            log.warn("AI forecast servisi ulaşılamadı: {}", e.getMessage());
        } catch (Exception e) {
            log.error("AI forecast beklenmedik hata", e);
        }
        return Map.of("forecast", List.of(), "trend", "unknown",
                "predicted_monthly", 0.0, "method", "none");
    }

    // =========================
    // TAM ANALİZ (tek istekte hepsi)
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public Map<String, Object> fullAnalyze(double totalAmount, double averageDaily,
                                           String topCategory,
                                           List<CategoryStatResponse> categoryStats,
                                           List<Double> amounts,
                                           List<Double> dailyAmounts) {
        try {
            List<Map<String, Object>> catList = categoryStats.stream()
                    .map(c -> Map.<String, Object>of(
                            "category", c.getCategory(),
                            "total", c.getTotal(),
                            "percentage", c.getPercentage()
                    ))
                    .toList();

            Map<String, Object> body = new HashMap<>();
            body.put("totalAmount", totalAmount);
            body.put("averageDaily", averageDaily);
            body.put("topCategory", topCategory);
            body.put("categoryStats", catList);
            body.put("amounts", amounts);
            body.put("dailyAmounts", dailyAmounts);

            ResponseEntity<Map> response = post("/full-analyze", body, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("AI tam analiz tamamlandı");
                return (Map<String, Object>) response.getBody();
            }
        } catch (RestClientException e) {
            log.warn("AI full-analyze servisi ulaşılamadı, parçalı analiz yapılıyor: {}", e.getMessage());
            return partialAnalyze(totalAmount, averageDaily, topCategory, categoryStats, amounts, dailyAmounts);
        } catch (Exception e) {
            log.error("AI full-analyze beklenmedik hata", e);
        }
        return partialAnalyze(totalAmount, averageDaily, topCategory, categoryStats, amounts, dailyAmounts);
    }

    // =========================
    // GEMİNİ FİŞ ANALİZİ
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public Map<String, Object> analyzeReceiptImage(byte[] imageBytes, String originalFilename) {
        try {
            String filename = originalFilename != null ? originalFilename : "receipt.jpg";

            LinkedMultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new ByteArrayResource(imageBytes) {
                @Override
                public String getFilename() { return filename; }
            });

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            HttpEntity<LinkedMultiValueMap<String, Object>> entity =
                    new HttpEntity<>(body, headers);

            ResponseEntity<Map> response = restTemplate().postForEntity(
                    aiServiceUrl + "/smart-ocr", entity, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("Fiş analizi tamamlandı: engine={}", response.getBody().getOrDefault("engine", "?"));
                return (Map<String, Object>) response.getBody();
            }
        } catch (HttpClientErrorException e) {
            log.warn("AI fiş analizi istemci hatası: {} {}", e.getStatusCode(), e.getResponseBodyAsString());
        } catch (RestClientException e) {
            log.warn("AI fiş analizi servisi ulaşılamadı: {}", e.getMessage());
        } catch (Exception e) {
            log.error("AI fiş analizi beklenmedik hata", e);
        }
        return Map.of("success", false, "error", "Fiş analizi şu anda kullanılamıyor");
    }

    // =========================
    // AKILLI BÜTÇE TAHMİNİ
    // =========================
    @Override
    @SuppressWarnings("unchecked")
    public Map<String, Object> getSmartBudget(List<Map<String, Object>> monthlyStats) {
        try {
            ResponseEntity<Map> response = post("/smart-budget", monthlyStats, Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("Akıllı bütçe tahmini alındı");
                return (Map<String, Object>) response.getBody();
            }
        } catch (RestClientException e) {
            log.warn("AI smart-budget servisi ulaşılamadı: {}", e.getMessage());
        } catch (Exception e) {
            log.error("AI smart-budget beklenmedik hata", e);
        }
        // Fallback: basit ortalama
        List<Map<String, Object>> items = monthlyStats.stream().map(s -> {
            double avg = ((Number) s.getOrDefault("avg", 0)).doubleValue();
            Map<String, Object> item = new java.util.LinkedHashMap<>();
            item.put("category", s.get("category"));
            item.put("avg3month", avg);
            item.put("recommended", Math.round(avg));
            item.put("trend", "sabit");
            item.put("reason", String.format("Son 3 ay ort. %.0f₺", avg));
            return item;
        }).toList();
        double total = items.stream().mapToDouble(i -> ((Number) i.get("recommended")).doubleValue()).sum();
        return Map.of("items", items, "total_recommended", total,
                "summary", String.format("Aylık önerilen toplam bütçe: %.0f₺", total));
    }

    @Override
    public boolean isGeminiAvailable() {
        try {
            ResponseEntity<Map> response = restTemplate()
                    .getForEntity(aiServiceUrl + "/gemini-status", Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Object available = response.getBody().get("available");
                return Boolean.TRUE.equals(available);
            }
        } catch (Exception e) {
            log.debug("Gemini durum kontrolü başarısız: {}", e.getMessage());
        }
        return false;
    }

    // =========================
    // FALLBACK: AI çalışmıyorsa parçalı çağır
    // =========================
    private Map<String, Object> partialAnalyze(double totalAmount, double averageDaily,
                                               String topCategory,
                                               List<CategoryStatResponse> categoryStats,
                                               List<Double> amounts,
                                               List<Double> dailyAmounts) {
        Map<String, Object> result = new HashMap<>();
        result.put("anomalies", detectAnomalies(amounts));
        result.put("budget_advice", getBudgetAdvice(totalAmount, averageDaily, categoryStats));
        result.put("forecast", getForecast(dailyAmounts, 7));
        result.put("insights", List.of("En çok harcadığın kategori: " + topCategory));
        return result;
    }

    // =========================
    // FALLBACK: AI tamamen çevrimdışı
    // =========================
    private Map<String, Object> fallbackBudget(double averageDaily, double totalAmount) {
        String riskLevel = averageDaily > 1000 ? "high" : averageDaily > 500 ? "medium" : "low";
        List<String> advice = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        if (riskLevel.equals("high")) {
            warnings.add("Günlük harcaman yüksek. Bütçe hedefi belirle.");
        } else if (riskLevel.equals("medium")) {
            advice.add("Harcamalarını kontrol altında tut.");
        } else {
            advice.add("Harcama disiplinin iyi görünüyor.");
        }

        if (totalAmount > 15000) warnings.add("Bu ay çok harcama yaptın!");

        return Map.of(
                "risk_level", riskLevel,
                "advice", advice,
                "warnings", warnings,
                "savings_potential", Math.max(0, averageDaily - 500) * 5
        );
    }
}

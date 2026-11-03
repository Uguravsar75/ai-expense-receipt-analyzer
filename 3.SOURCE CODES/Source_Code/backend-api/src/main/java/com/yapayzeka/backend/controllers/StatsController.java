package com.yapayzeka.backend.controllers;

import com.yapayzeka.backend.controllers.dto.CategoryStatResponse;
import com.yapayzeka.backend.controllers.dto.DailyStatResponse;
import com.yapayzeka.backend.controllers.dto.SummaryResponse;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.repositories.ExpenseRepository;
import com.yapayzeka.backend.repositories.UserRepository;
import com.yapayzeka.backend.services.AIService;
import com.yapayzeka.backend.services.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/stats")
@RequiredArgsConstructor
public class StatsController {

    private final ExpenseService expenseService;
    private final UserRepository userRepository;
    private final AIService aiService;
    private final ExpenseRepository expenseRepository;

    // =========================
    // 🔐 USER FROM JWT
    // =========================
    private User getUser(Authentication authentication) {
        if (authentication == null) {
            throw new RuntimeException("Unauthorized");
        }

        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    // =========================
    // 📊 SUMMARY
    // =========================
    @GetMapping("/summary")
    public ResponseEntity<SummaryResponse> getSummary(Authentication authentication) {
        User user = getUser(authentication);
        return ResponseEntity.ok(
                expenseService.getSummary(user.getId())
        );
    }

    // =========================
    // 📊 CATEGORY STATS
    // =========================
    @GetMapping("/category")
    public ResponseEntity<List<CategoryStatResponse>> getCategoryStats(
            Authentication authentication
    ) {
        User user = getUser(authentication);
        return ResponseEntity.ok(
                expenseService.getCategoryStats(user.getId())
        );
    }

    // =========================
    // 🧠 AI INSIGHTS
    // =========================
    @GetMapping("/insights")
    public ResponseEntity<Map<String, Object>> getInsights(
            Authentication authentication
    ) {
        User user = getUser(authentication);
        return ResponseEntity.ok(
                expenseService.getInsights(user.getId())
        );
    }

    // =========================
    // 📊 DAILY BAR CHART
    // =========================
    @GetMapping("/daily")
    public ResponseEntity<List<DailyStatResponse>> getDailyStats(
            @RequestParam(name = "days", defaultValue = "7") int days,
            Authentication authentication
    ) {
        User user = getUser(authentication);
        return ResponseEntity.ok(
                expenseService.getDailyStats(user.getId(), days)
        );
    }

    // =========================
    // 🤖 AI ANALYZE
    // =========================
    @GetMapping("/analyze")
    public ResponseEntity<Map<String, Object>> analyze(
            Authentication authentication
    ) {
        User user = getUser(authentication);
        return ResponseEntity.ok(
                expenseService.analyze(user.getId())
        );
    }

    // =========================
    // 🧠 AKILLI BÜTÇE TAHMİNİ (son 3 ay)
    // GET /stats/smart-budget
    // =========================
    @GetMapping("/smart-budget")
    public ResponseEntity<Map<String, Object>> getSmartBudget(Authentication authentication) {
        User user = getUser(authentication);
        LocalDate today = LocalDate.now();

        // Son 3 ayın başlangıç tarihlerini hesapla
        LocalDateTime m1Start = today.minusMonths(3).withDayOfMonth(1).atStartOfDay();
        LocalDateTime m1End   = today.minusMonths(2).withDayOfMonth(1).atStartOfDay();
        LocalDateTime m2Start = m1End;
        LocalDateTime m2End   = today.minusMonths(1).withDayOfMonth(1).atStartOfDay();
        LocalDateTime m3Start = m2End;
        LocalDateTime m3End   = today.withDayOfMonth(1).atStartOfDay();

        // Her ay için kategori toplamlarını çek
        Map<String, Double> month1 = toMap(expenseRepository.sumByCategoryBetween(user, m1Start, m1End));
        Map<String, Double> month2 = toMap(expenseRepository.sumByCategoryBetween(user, m2Start, m2End));
        Map<String, Double> month3 = toMap(expenseRepository.sumByCategoryBetween(user, m3Start, m3End));

        // Tüm kategorileri birleştir
        Set<String> allCats = new HashSet<>();
        allCats.addAll(month1.keySet());
        allCats.addAll(month2.keySet());
        allCats.addAll(month3.keySet());

        if (allCats.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                "items", List.of(),
                "total_recommended", 0,
                "summary", "Henüz yeterli harcama verisi yok."
            ));
        }

        List<Map<String, Object>> monthlyStats = allCats.stream().map(cat -> {
            double v1 = month1.getOrDefault(cat, 0.0);
            double v2 = month2.getOrDefault(cat, 0.0);
            double v3 = month3.getOrDefault(cat, 0.0);
            double avg = (v1 + v2 + v3) / 3.0;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("category", cat);
            m.put("month1", v1);
            m.put("month2", v2);
            m.put("month3", v3);
            m.put("avg", avg);
            return m;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(aiService.getSmartBudget(monthlyStats));
    }

    private Map<String, Double> toMap(List<Object[]> rows) {
        Map<String, Double> map = new HashMap<>();
        for (Object[] row : rows) {
            String cat = (String) row[0];
            double amt = row[1] instanceof Number ? ((Number) row[1]).doubleValue() : 0.0;
            map.put(cat, amt);
        }
        return map;
    }

    // =========================
    // 💰 BÜTÇE TAVSİYELERİ
    // GET /stats/budget-advice   (Flutter bu endpoint'i çağırıyor)
    // GET /expenses/budget-advice  alias → buraya yönlendirildi
    // =========================
    @GetMapping("/budget-advice")
    public ResponseEntity<Map<String, Object>> getBudgetAdvice(Authentication authentication) {
        User user = getUser(authentication);
        SummaryResponse summary = expenseService.getSummary(user.getId());
        java.util.List<CategoryStatResponse> categoryStats = expenseService.getCategoryStats(user.getId());
        return ResponseEntity.ok(
                aiService.getBudgetAdvice(summary.getTotalAmount(), summary.getAverageDaily(), categoryStats)
        );
    }
}

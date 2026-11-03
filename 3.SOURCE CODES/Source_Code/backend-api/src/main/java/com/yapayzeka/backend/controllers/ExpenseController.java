package com.yapayzeka.backend.controllers;

import com.yapayzeka.backend.controllers.dto.ExpenseRequest;
import com.yapayzeka.backend.entities.Expense;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.repositories.UserRepository;
import com.yapayzeka.backend.services.AIService;
import com.yapayzeka.backend.services.ExpenseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/expenses")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;
    private final UserRepository userRepository;
    private final AIService aiService;

    // ========================
    // CREATE
    // ========================
    @PostMapping
    public ResponseEntity<?> createExpense(
            @Valid @RequestBody ExpenseRequest request,
            Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        Expense saved = expenseService.createExpense(request, authentication.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // ========================
    // READ (USER)
    // ========================
    @GetMapping
    public ResponseEntity<?> getMyExpenses(Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Expense> expenses = expenseService.getMyExpenses(user);
        return ResponseEntity.ok(expenses);
    }

    // ========================
    // READ BY ID
    // ========================
    @GetMapping("/{id}")
    public ResponseEntity<?> getExpenseById(
            @PathVariable Long id,
            Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Expense expense = expenseService.getExpenseById(id);
        if (!expense.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bu harcama size ait değil");
        }
        return ResponseEntity.ok(expense);
    }

    // ========================
    // READ BY CATEGORY
    // ========================
    @GetMapping("/category/{category}")
    public ResponseEntity<?> getByCategory(
            @PathVariable String category,
            Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(
                expenseService.getExpensesByCategoryAndUser(category, user));
    }

    // ========================
    // UPDATE
    // ========================
    @PutMapping("/{id}")
    public ResponseEntity<?> updateExpense(
            @PathVariable Long id,
            @RequestBody Expense expense,
            Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Expense existing = expenseService.getExpenseById(id);
        if (!existing.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bu harcama size ait değil");
        }
        return ResponseEntity.ok(expenseService.updateExpense(id, expense));
    }

    // ========================
    // DELETE (USER SAFE) 🔥
    // ========================
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteExpenseByUser(
            @PathVariable Long id,
            Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        expenseService.deleteExpenseByUser(id, authentication.getName());
        return ResponseEntity.noContent().build();
    }

    // ========================
    // DELETE ALL (kullanıcının tüm harcamalarını sil)
    // ========================
    @DeleteMapping("/all")
    public ResponseEntity<?> deleteAllExpenses(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        int deleted = expenseService.deleteAllByUser(authentication.getName());
        return ResponseEntity.ok(java.util.Map.of("deleted", deleted));
    }

    // ========================
    // STATS
    // ========================
    @GetMapping("/stats")
    public ResponseEntity<?> getStats(Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<String, Long> stats = expenseService.getStatsByUser(user);
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/stats/category")
    public ResponseEntity<?> getCategoryStats(Authentication auth) {

        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(
                expenseService.getCategoryStats(user));
    }

    // ========================
    // DASHBOARD SUMMARY
    // GET /expenses/dashboard
    // ========================
    @GetMapping("/dashboard")
    public ResponseEntity<?> getDashboard(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Bu ayki harcamalar
        java.time.LocalDateTime startOfMonth = java.time.LocalDateTime.now()
                .withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0).withNano(0);
        List<Expense> all = expenseService.getMyExpenses(user);
        double monthlyTotal = all.stream()
                .filter(e -> e.getCreatedAt() != null && e.getCreatedAt().isAfter(startOfMonth))
                .mapToDouble(Expense::getAmount).sum();

        // Kategori dağılımı (tüm zamanlar)
        List<com.yapayzeka.backend.controllers.dto.CategoryStatResponse> categoryStats =
                expenseService.getCategoryStats(user.getId());

        // Son 7 gün
        List<com.yapayzeka.backend.controllers.dto.DailyStatResponse> dailyStats =
                expenseService.getDailyStats(user.getId(), 7);

        // Son 5 harcama
        List<Expense> recent = all.stream()
                .sorted((a, b) -> {
                    if (a.getCreatedAt() == null) return 1;
                    if (b.getCreatedAt() == null) return -1;
                    return b.getCreatedAt().compareTo(a.getCreatedAt());
                })
                .limit(5)
                .toList();

        return ResponseEntity.ok(Map.of(
                "monthlyTotal", monthlyTotal,
                "totalCount", all.size(),
                "categoryStats", categoryStats,
                "dailyStats", dailyStats,
                "recentExpenses", recent
        ));
    }

    // ========================
    // SMART ANALYSIS — ay karşılaştırması
    // GET /expenses/smart-analysis
    // ========================
    @GetMapping("/smart-analysis")
    public ResponseEntity<?> getSmartAnalysis(Authentication authentication) {
        if (authentication == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Expense> all = expenseService.getMyExpenses(user);
        java.time.LocalDateTime now = java.time.LocalDateTime.now();

        // Bu ay
        java.time.LocalDateTime startThisMonth = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0).withNano(0);
        // Geçen ay
        java.time.LocalDateTime startLastMonth = startThisMonth.minusMonths(1);
        java.time.LocalDateTime endLastMonth = startThisMonth;

        Map<String, Double> thisMonthByCategory = new java.util.HashMap<>();
        Map<String, Double> lastMonthByCategory = new java.util.HashMap<>();
        double thisMonthTotal = 0, lastMonthTotal = 0;

        for (Expense e : all) {
            if (e.getCreatedAt() == null) continue;
            String cat = e.getCategory() != null ? e.getCategory() : "Diğer";
            if (!e.getCreatedAt().isBefore(startThisMonth)) {
                thisMonthTotal += e.getAmount();
                thisMonthByCategory.merge(cat, e.getAmount(), Double::sum);
            } else if (!e.getCreatedAt().isBefore(startLastMonth) && e.getCreatedAt().isBefore(endLastMonth)) {
                lastMonthTotal += e.getAmount();
                lastMonthByCategory.merge(cat, e.getAmount(), Double::sum);
            }
        }

        // Kategori bazlı karşılaştırmalar
        java.util.Set<String> allCats = new java.util.HashSet<>();
        allCats.addAll(thisMonthByCategory.keySet());
        allCats.addAll(lastMonthByCategory.keySet());

        List<Map<String, Object>> comparisons = new java.util.ArrayList<>();
        for (String cat : allCats) {
            double thisVal = thisMonthByCategory.getOrDefault(cat, 0.0);
            double lastVal = lastMonthByCategory.getOrDefault(cat, 0.0);
            double changePct = lastVal > 0 ? ((thisVal - lastVal) / lastVal) * 100 : (thisVal > 0 ? 100.0 : 0.0);
            Map<String, Object> item = new java.util.HashMap<>();
            item.put("category", cat);
            item.put("thisMonth", thisVal);
            item.put("lastMonth", lastVal);
            item.put("changePct", Math.round(changePct * 10.0) / 10.0);
            comparisons.add(item);
        }
        comparisons.sort((a, b) -> Double.compare(
                Math.abs((double) b.get("thisMonth")),
                Math.abs((double) a.get("thisMonth"))));

        // Toplam değişim
        double totalChangePct = lastMonthTotal > 0
                ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100 : 0;

        // İçgörü mesajları
        List<String> insights = new java.util.ArrayList<>();
        if (lastMonthTotal > 0) {
            if (totalChangePct > 20) {
                insights.add(String.format("Bu ay geçen aya göre %%%,.0f daha fazla harcama yaptın.", totalChangePct));
            } else if (totalChangePct < -20) {
                insights.add(String.format("Bu ay geçen aya göre %%%,.0f daha az harcama yaptın. Harika!", Math.abs(totalChangePct)));
            } else {
                insights.add("Bu ay harcamaların geçen ayla benzer seyretti.");
            }
        }
        for (Map<String, Object> comp : comparisons) {
            double pct = (double) comp.get("changePct");
            String cat = (String) comp.get("category");
            if (pct >= 30) {
                insights.add(String.format("%s harcamaların geçen aya göre %%%,.0f arttı.", cat, pct));
            } else if (pct <= -30) {
                insights.add(String.format("%s harcamaların geçen aya göre %%%,.0f azaldı.", cat, Math.abs(pct)));
            }
        }

        return ResponseEntity.ok(Map.of(
                "thisMonthTotal", thisMonthTotal,
                "lastMonthTotal", lastMonthTotal,
                "totalChangePct", Math.round(totalChangePct * 10.0) / 10.0,
                "comparisons", comparisons,
                "insights", insights,
                "thisMonthName", now.getMonth().getDisplayName(java.time.format.TextStyle.FULL, java.util.Locale.of("tr")),
                "lastMonthName", now.minusMonths(1).getMonth().getDisplayName(java.time.format.TextStyle.FULL, java.util.Locale.of("tr"))
        ));
    }

    // ========================
    // RECURRING EXPENSE DETECTION
    // GET /expenses/recurring
    // ========================
    @GetMapping("/recurring")
    public ResponseEntity<?> getRecurring(Authentication authentication) {
        if (authentication == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Expense> all = expenseService.getMyExpenses(user);

        // Açıklama bazlı gruplama (küçük harf, normalize)
        Map<String, List<Expense>> byDesc = new java.util.HashMap<>();
        for (Expense e : all) {
            if (e.getDescription() == null || e.getDescription().isBlank()) continue;
            String key = e.getDescription().trim().toLowerCase(java.util.Locale.ROOT);
            byDesc.computeIfAbsent(key, k -> new java.util.ArrayList<>()).add(e);
        }

        List<Map<String, Object>> recurring = new java.util.ArrayList<>();
        for (Map.Entry<String, List<Expense>> entry : byDesc.entrySet()) {
            List<Expense> group = entry.getValue();
            if (group.size() < 2) continue;

            // Kaç farklı ayda geçiyor?
            java.util.Set<String> months = new java.util.HashSet<>();
            double totalAmt = 0;
            for (Expense e : group) {
                if (e.getCreatedAt() != null) {
                    months.add(e.getCreatedAt().getYear() + "-" + e.getCreatedAt().getMonthValue());
                }
                totalAmt += e.getAmount();
            }
            if (months.size() < 2) continue;

            double avgAmount = totalAmt / group.size();
            String cat = group.get(0).getCategory() != null ? group.get(0).getCategory() : "Diğer";
            String desc = group.get(0).getDescription();

            Map<String, Object> item = new java.util.HashMap<>();
            item.put("description", desc);
            item.put("category", cat);
            item.put("count", group.size());
            item.put("monthCount", months.size());
            item.put("avgAmount", Math.round(avgAmount * 100.0) / 100.0);
            item.put("totalAmount", Math.round(totalAmt * 100.0) / 100.0);
            recurring.add(item);
        }

        // En çok tekrarlayandan sırala
        recurring.sort((a, b) -> Integer.compare((int) b.get("monthCount"), (int) a.get("monthCount")));

        return ResponseEntity.ok(Map.of("recurring", recurring, "count", recurring.size()));
    }

    // ========================
    // AI CANLI KATEGORİ TAHMİNİ
    // POST /expenses/predict?text=migros alışveriş
    // ========================
    @PostMapping("/predict")
    public ResponseEntity<Map<String, String>> predictCategory(
            @RequestBody Map<String, String> body,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String text = body.getOrDefault("text", "").trim();
        if (text.isEmpty()) {
            return ResponseEntity.ok(Map.of("category", "unknown", "confidence", "low"));
        }

        String predicted = aiService.predictCategory(text);
        return ResponseEntity.ok(Map.of(
                "category", predicted != null ? predicted : "unknown",
                "confidence", "high"
        ));
    }

    // ========================
    // AI DOĞRULUK GERİ BİLDİRİMİ
    // PATCH /expenses/{id}/feedback
    // Body: { "accepted": true/false, "correctedCategory": "FOOD" }
    // ========================
    @PatchMapping("/{id}/feedback")
    public ResponseEntity<?> submitFeedback(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        Boolean accepted = (Boolean) body.get("accepted");
        String correctedCategory = (String) body.get("correctedCategory");

        expenseService.submitAiFeedback(id, authentication.getName(), accepted, correctedCategory);
        return ResponseEntity.ok(Map.of("message", "Geri bildirim kaydedildi"));
    }

    // ========================
    // FULL AI ANALİZİ
    // GET /expenses/full-analysis
    // ========================
    @GetMapping("/full-analysis")
    public ResponseEntity<Map<String, Object>> getFullAnalysis(Authentication authentication) {
        if (authentication == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Expense> expenses = expenseService.getMyExpenses(user);
        if (expenses.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                "anomalies", List.of(),
                "budget_advice", Map.of("advice", List.of(), "warnings", List.of("Henüz harcama yok."), "savings_potential", 0, "risk_level", "low"),
                "forecast", Map.of("forecast", List.of(), "predicted_daily_avg", 0, "predicted_monthly", 0, "trend", "stable", "method", "none"),
                "insights", List.of("Henüz harcama kaydı yok.")
            ));
        }

        // Kategori istatistikleri
        var catStats = expenseService.getCategoryStats(user.getId());
        double total = expenses.stream().mapToDouble(e -> e.getAmount()).sum();
        double avgDaily = expenses.isEmpty() ? 0 : total / 30.0;
        String topCat = catStats.isEmpty() ? "Diğer" : catStats.get(0).getCategory();

        // Tüm tutarlar (anomali için)
        List<Double> amounts = expenses.stream()
                .map(e -> e.getAmount()).toList();

        // Son 30 günlük daily amounts (tahmin için)
        var now = java.time.LocalDate.now();
        List<Double> dailyAmounts = new java.util.ArrayList<>();
        for (int i = 29; i >= 0; i--) {
            final var day = now.minusDays(i);
            double dayTotal = expenses.stream()
                    .filter(e -> e.getCreatedAt() != null && e.getCreatedAt().toLocalDate().equals(day))
                    .mapToDouble(e -> e.getAmount()).sum();
            dailyAmounts.add(dayTotal);
        }

        Map<String, Object> result = aiService.fullAnalyze(
                total, avgDaily, topCat, catStats, amounts, dailyAmounts);
        return ResponseEntity.ok(result);
    }

    // ========================
    // AI DOĞRULUK ORANI
    // GET /expenses/accuracy
    // ========================
    @GetMapping("/accuracy")
    public ResponseEntity<Map<String, Object>> getAccuracy(Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(expenseService.getAiAccuracy(user));
    }

}

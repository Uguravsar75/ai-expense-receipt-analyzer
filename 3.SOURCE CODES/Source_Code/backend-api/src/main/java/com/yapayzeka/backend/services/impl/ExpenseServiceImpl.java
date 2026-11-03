package com.yapayzeka.backend.services.impl;

import com.yapayzeka.backend.controllers.dto.*;
import com.yapayzeka.backend.entities.Expense;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.exception.*;
import com.yapayzeka.backend.repositories.ExpenseRepository;
import com.yapayzeka.backend.repositories.UserRepository;
import com.yapayzeka.backend.services.AIService;
import com.yapayzeka.backend.services.ExpenseService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.sql.Timestamp;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class ExpenseServiceImpl implements ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final UserRepository userRepository;
    private final AIService aiService;

    // ========================
    // NORMALIZATION
    // ========================
    private static final Map<String, String> CATEGORY_MAP = Map.of(
        "market", "Market",
        "yeme ve icme", "Yeme & İçme",
        "yeme & içme", "Yeme & İçme",
        "faturalar", "Faturalar",
        "ulasim", "Ulaşım",
        "ulaşım", "Ulaşım",
        "kira ve ev", "Kira & Ev",
        "kira & ev", "Kira & Ev",
        "saglik", "Sağlık",
        "sağlık", "Sağlık"
    );

    private static final Map<String, String> CATEGORY_MAP2 = Map.of(
        "eglence", "Eğlence",
        "eğlence", "Eğlence",
        "giyim", "Giyim",
        "egitim", "Eğitim",
        "eğitim", "Eğitim",
        "diger", "Diğer",
        "diğer", "Diğer",
        "other", "Diğer",
        "food", "Yeme & İçme",
        "transport", "Ulaşım"
    );

    private String normalizeCategory(String category) {
        if (category == null || category.trim().isEmpty()) return "Diğer";
        String key = category.trim().toLowerCase(Locale.ROOT);
        String mapped = CATEGORY_MAP.get(key);
        if (mapped != null) return mapped;
        mapped = CATEGORY_MAP2.get(key);
        if (mapped != null) return mapped;
        // Bilinen kategorilerden biri mi?
        List<String> known = List.of("Market","Yeme & İçme","Faturalar","Ulaşım",
                "Kira & Ev","Sağlık","Eğlence","Giyim","Eğitim","Diğer");
        for (String k : known) {
            if (k.equalsIgnoreCase(category.trim())) return k;
        }
        return category.trim(); // olduğu gibi sakla
    }

    private String normalizeText(String text) {
        if (text == null) return null;
        String t = text.trim();
        return t.isEmpty() ? null : t;
    }

    // ========================
    // CREATE
    // ========================
    @Override
    public Expense createExpense(ExpenseRequest request, String userEmail) {
        log.info("Creating expense for user: {}", userEmail);

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> {
                    log.error("User not found: {}", userEmail);
                    return new UserNotFoundException("Kullanıcı bulunamadı: " + userEmail);
                });

        Expense expense = new Expense();
        expense.setAmount(request.getAmount());
        expense.setCategory(normalizeCategory(request.getCategory()));
        expense.setDescription(normalizeText(request.getDescription()));
        expense.setUser(user);

        // 🤖 AI prediction (fail-safe)
        try {
            String predicted = aiService.predictCategory(expense.getDescription());
            if (predicted != null && !predicted.isBlank() && !"unknown".equalsIgnoreCase(predicted)) {
                expense.setPredictedCategory(normalizeCategory(predicted));
            } else {
                expense.setPredictedCategory("unknown");
            }
            log.debug("AI prediction for description '{}': {}", expense.getDescription(), expense.getPredictedCategory());
        } catch (Exception e) {
            log.warn("AI prediction failed, using 'unknown': {}", e.getMessage());
            expense.setPredictedCategory("unknown");
        }

        Expense saved = expenseRepository.save(expense);
        log.info("Expense created successfully for user: {} with amount: {}", userEmail, request.getAmount());
        return saved;
    }

    // ========================
    // READ
    // ========================
    @Override
    public Expense getExpenseById(Long id) {
        log.debug("Fetching expense by id: {}", id);
        return expenseRepository.findById(id)
                .orElseThrow(() -> {
                    log.error("Expense not found: {}", id);
                    return new ExpenseNotFoundException("Harcama bulunamadı: " + id);
                });
    }

    @Override
    public List<Expense> getMyExpenses(User user) {
        log.debug("Fetching all expenses for user: {}", user.getEmail());
        return expenseRepository.findByUser(user);
    }

    @Override
    public List<Expense> getExpensesByCategoryAndUser(String category, User user) {
        log.debug("Fetching expenses by category: {} for user: {}", category, user.getEmail());
        return expenseRepository.findByCategoryIgnoreCaseAndUser(
                normalizeCategory(category), user
        );
    }

    // ========================
    // UPDATE
    // ========================
    @Override
    public Expense updateExpense(Long id, Expense expense) {
        log.info("Updating expense: {}", id);

        Expense existing = getExpenseById(id);

        existing.setAmount(expense.getAmount());
        existing.setCategory(normalizeCategory(expense.getCategory()));
        existing.setDescription(normalizeText(expense.getDescription()));
        existing.setPredictedCategory(normalizeText(expense.getPredictedCategory()));

        Expense updated = expenseRepository.save(existing);
        log.info("Expense updated successfully: {}", id);
        return updated;
    }

    // ========================
    // DELETE (USER SAFE) ✅
    // ========================
    @Override
    public void deleteExpenseByUser(Long expenseId, String email) {
        log.info("Deleting expense: {} for user: {}", expenseId, email);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found: {}", email);
                    return new UserNotFoundException("Kullanıcı bulunamadı");
                });

        Expense expense = expenseRepository.findByIdAndUser(expenseId, user)
                .orElseThrow(() -> {
                    log.error("Expense not found or not owned by user: {}", expenseId);
                    return new ExpenseNotFoundException(
                            "Harcama bulunamadı veya sizin değil: " + expenseId
                    );
                });

        expenseRepository.delete(expense);
        log.info("Expense deleted successfully: {}", expenseId);
    }

    @Override
    public int deleteAllByUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("Kullanıcı bulunamadı"));
        List<Expense> expenses = expenseRepository.findByUser(user);
        expenseRepository.deleteAll(expenses);
        log.info("Deleted {} expenses for user: {}", expenses.size(), email);
        return expenses.size();
    }

    // ========================
    // SUMMARY
    // ========================
    @Override
    public SummaryResponse getSummary(Long userId) {
        log.debug("Getting summary for user: {}", userId);
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> {
                        log.error("User not found: {}", userId);
                        return new UserNotFoundException("Kullanıcı bulunamadı");
                    });

            Double total = expenseRepository.sumAmountByUser(user);

            if (total == null || total == 0) {
                log.debug("No expenses found for user: {}", userId);
                return new SummaryResponse(0.0, 0.0, "NONE");
            }

            long daySpan = 1;
            try {
                Object[] dateRange = expenseRepository.findDateRangeByUser(user);
                if (dateRange != null && dateRange.length >= 2 && dateRange[0] != null && dateRange[1] != null) {
                    LocalDateTime first = toLocalDateTime(dateRange[0]);
                    LocalDateTime last = toLocalDateTime(dateRange[1]);
                    if (first != null && last != null) {
                        daySpan = Math.max(1, ChronoUnit.DAYS.between(first.toLocalDate(), last.toLocalDate()) + 1);
                    }
                }
            } catch (Exception e) {
                log.warn("DateRange hesaplama hatası, daySpan=1 kullanılıyor: {}", e.getMessage(), e);
            }

            double averageDaily = total / daySpan;

            String topCategory = "NONE";
            try {
                List<Object[]> categorySums = expenseRepository.sumAmountGroupByCategory(user);
                topCategory = categorySums.stream()
                        .max(Comparator.comparingDouble(o -> ((Number) o[1]).doubleValue()))
                        .map(o -> normalizeCategory((String) o[0]))
                        .orElse("NONE");
            } catch (Exception e) {
                log.warn("TopCategory hesaplama hatası: {}", e.getMessage(), e);
            }

            log.debug("Summary for user {}: total={}, avgDaily={}, topCat={}", userId, total, averageDaily, topCategory);
            return new SummaryResponse(total, averageDaily, topCategory);

        } catch (UserNotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.error("getSummary beklenmedik hata: userId={}, hata={}", userId, e.getMessage(), e);
            return new SummaryResponse(0.0, 0.0, "NONE");
        }
    }

    // ========================
    // CATEGORY STATS (PIE)
    // ========================
    @Override
    public List<CategoryStatResponse> getCategoryStats(Long userId) {
        log.debug("Getting category stats for user: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.error("User not found: {}", userId);
                    return new UserNotFoundException("Kullanıcı bulunamadı");
                });

        Double totalAmount = expenseRepository.sumAmountByUser(user);
        if (totalAmount == null || totalAmount == 0) {
            log.debug("No expenses found for category stats, user: {}", userId);
            return List.of();
        }

        List<Object[]> rows =
                expenseRepository.sumAmountGroupByCategory(user);

        Map<String, Double> merged = new LinkedHashMap<>();
        for (Object[] r : rows) {
            String category = normalizeCategory((String) r[0]);
            Double sum = ((Number) r[1]).doubleValue();
            merged.merge(category, sum, Double::sum);
        }

        return merged.entrySet().stream()
                .map(entry -> {
                    String category = entry.getKey();
                    Double sum = entry.getValue();
                    Double percentage = (sum / totalAmount) * 100.0;
                    return new CategoryStatResponse(category, sum, percentage);
                })
                .sorted(Comparator.comparingDouble(CategoryStatResponse::getTotal).reversed())
                .toList();
    }

    // ========================
    // 🧠 AI INSIGHTS
    // ========================
    @Override
    public Map<String, Object> getInsights(Long userId) {
        log.debug("Getting insights for user: {}", userId);
        try {
            SummaryResponse summary = getSummary(userId);
            List<CategoryStatResponse> categories = getCategoryStats(userId);

            List<String> insights = new ArrayList<>();

            if (summary.getTotalAmount() > 5000) {
                insights.add("Bu ay harcamaların oldukça yüksek.");
            }

            categories.stream()
                    .max(Comparator.comparingDouble(CategoryStatResponse::getPercentage))
                    .ifPresent(cat ->
                            insights.add("En çok harcama yapılan kategori: " + cat.getCategory())
                    );

            log.debug("Generated {} insights for user: {}", insights.size(), userId);

            Map<String, Object> result = new HashMap<>();
            result.put("summary", summary);
            result.put("categoryStats", categories);
            result.put("insights", insights);
            return result;

        } catch (UserNotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.error("getInsights beklenmedik hata: userId={}, hata={}", userId, e.getMessage(), e);
            Map<String, Object> fallback = new HashMap<>();
            fallback.put("summary", new SummaryResponse(0.0, 0.0, "NONE"));
            fallback.put("categoryStats", List.of());
            fallback.put("insights", List.of());
            return fallback;
        }
    }

    // ========================
    // 📊 DAILY STATS (BAR)
    // ========================
    @Override
    public List<DailyStatResponse> getDailyStats(Long userId, int days) {
        log.debug("Getting daily stats for user: {} (last {} days)", userId, days);
        try {
            LocalDateTime startDate = LocalDateTime.now().minusDays(days);
            List<Object[]> rows = expenseRepository.sumDailyExpenses(userId, startDate);
            log.debug("Found {} daily stats entries for user: {}", rows.size(), userId);
            return rows.stream()
                    .filter(r -> r[0] != null && r[1] != null)
                    .map(r -> new DailyStatResponse(r[0].toString(), ((Number) r[1]).doubleValue()))
                    .toList();
        } catch (Exception e) {
            log.error("getDailyStats hata: userId={}, hata={}", userId, e.getMessage(), e);
            return List.of();
        }
    }

    @Override
    public Expense saveExpense(Expense expense) {
        log.debug("Saving expense with amount: {}", expense.getAmount());
        return expenseRepository.save(expense);
    }

    @Override
    public void deleteExpense(Long id) {
        log.info("Deleting expense: {}", id);
        expenseRepository.deleteById(id);
    }

    @Override
    public Map<String, Long> getStatsByUser(User user) {
        log.debug("Getting basic stats for user: {}", user.getEmail());
        
        List<Expense> expenses = expenseRepository.findByUser(user);
        Map<String, Long> stats = new HashMap<>();
        
        for (Expense expense : expenses) {
            String category = normalizeCategory(expense.getCategory());
            stats.put(category, stats.getOrDefault(category, 0L) + 1);
        }
        
        return stats;
    }

    // ========================
    // AI GERİ BİLDİRİM
    // ========================
    @Override
    public void submitAiFeedback(Long expenseId, String userEmail, Boolean accepted, String correctedCategory) {
        log.info("AI geri bildirimi: expenseId={}, accepted={}", expenseId, accepted);

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UserNotFoundException("Kullanıcı bulunamadı"));

        Expense expense = expenseRepository.findByIdAndUser(expenseId, user)
                .orElseThrow(() -> new ExpenseNotFoundException("Harcama bulunamadı: " + expenseId));

        expense.setAiAccepted(accepted);

        // Kullanıcı düzelttiyse kategoriyi güncelle
        if (Boolean.FALSE.equals(accepted) && correctedCategory != null && !correctedCategory.isBlank()) {
            expense.setCategory(normalizeCategory(correctedCategory));
            log.info("Kategori düzeltildi: {} → {}", expense.getPredictedCategory(), correctedCategory);
        }

        expenseRepository.save(expense);
    }

    // ========================
    // AI DOĞRULUK ORANI
    // ========================
    @Override
    public Map<String, Object> getAiAccuracy(User user) {
        List<Expense> expenses = expenseRepository.findByUser(user);

        // === GENEL METRİKLER ===
        long total = expenses.size();
        long withPrediction = expenses.stream()
                .filter(e -> e.getPredictedCategory() != null
                        && !e.getPredictedCategory().isBlank()
                        && !"unknown".equalsIgnoreCase(e.getPredictedCategory()))
                .count();
        long evaluated = expenses.stream()
                .filter(e -> e.getAiAccepted() != null).count();
        long accepted = expenses.stream()
                .filter(e -> Boolean.TRUE.equals(e.getAiAccepted())).count();
        long rejected = expenses.stream()
                .filter(e -> Boolean.FALSE.equals(e.getAiAccepted())).count();

        double accuracyRate = evaluated > 0 ? (double) accepted / evaluated * 100 : 0;

        // === KATEGORİ BAZLI DOĞRULUK ===
        // Her kategori için: {category, total, correct, accuracy}
        Map<String, long[]> catStats = new HashMap<>();
        // [0]=toplam tahmin, [1]=doğru tahmin
        for (Expense e : expenses) {
            String predicted = e.getPredictedCategory();
            if (predicted == null || predicted.isBlank()
                    || "unknown".equalsIgnoreCase(predicted)) continue;
            if (e.getAiAccepted() == null) continue;

            catStats.computeIfAbsent(predicted.toUpperCase(), k -> new long[]{0, 0});
            catStats.get(predicted.toUpperCase())[0]++;
            if (Boolean.TRUE.equals(e.getAiAccepted())) {
                catStats.get(predicted.toUpperCase())[1]++;
            }
        }

        List<Map<String, Object>> categoryAccuracy = catStats.entrySet().stream()
                .map(entry -> {
                    long catTotal = entry.getValue()[0];
                    long catCorrect = entry.getValue()[1];
                    double catAcc = catTotal > 0 ? (double) catCorrect / catTotal * 100 : 0;
                    Map<String, Object> m = new HashMap<>();
                    m.put("category", entry.getKey());
                    m.put("total", catTotal);
                    m.put("correct", catCorrect);
                    m.put("accuracy", Math.round(catAcc * 10.0) / 10.0);
                    return m;
                })
                .sorted((a, b) -> Long.compare((long) b.get("total"), (long) a.get("total")))
                .toList();

        // === TAHMİN ≠ GERÇEK → HANGİ KATEGORİYE GİTTİ (basit confusion) ===
        // predicted → corrected eşleşmeleri
        List<Map<String, String>> corrections = expenses.stream()
                .filter(e -> Boolean.FALSE.equals(e.getAiAccepted())
                        && e.getPredictedCategory() != null
                        && e.getCategory() != null
                        && !e.getPredictedCategory().equalsIgnoreCase(e.getCategory()))
                .map(e -> {
                    Map<String, String> m = new HashMap<>();
                    m.put("predicted", e.getPredictedCategory().toUpperCase());
                    m.put("corrected", e.getCategory().toUpperCase());
                    return m;
                })
                .toList();

        log.info("AI doğruluk raporu: toplam={}, tahmin={}, değerlendirilen={}, doğru={}, oran={}%",
                total, withPrediction, evaluated, accepted, Math.round(accuracyRate * 10.0) / 10.0);

        Map<String, Object> result = new HashMap<>();
        result.put("totalExpenses", total);
        result.put("withAiPrediction", withPrediction);
        result.put("evaluated", evaluated);
        result.put("accepted", accepted);
        result.put("rejected", rejected);
        result.put("accuracyRate", Math.round(accuracyRate * 10.0) / 10.0);
        result.put("categoryAccuracy", categoryAccuracy);
        result.put("corrections", corrections);
        result.put("message", evaluated == 0
                ? "Henüz değerlendirme yapılmadı"
                : String.format("AI tahminlerinin %.1f%%'i doğru (%d/%d)", accuracyRate, accepted, evaluated));
        return result;
    }

    @Override
    public Map<String, Double> getCategoryStats(User user) {
        log.debug("Getting category total amounts for user: {}", user.getEmail());
        
        List<Object[]> rows = expenseRepository.sumAmountGroupByCategory(user);
        Map<String, Double> stats = new HashMap<>();
        
        for (Object[] row : rows) {
            String category = normalizeCategory((String) row[0]);
            Double amount = ((Number) row[1]).doubleValue();
            stats.merge(category, amount, Double::sum);
        }
        
        return stats;
    }

    // ========================
    // 🤖 AI ANALYZE — Python AI servisi kullanır
    // ========================
    private LocalDateTime toLocalDateTime(Object val) {
        if (val instanceof LocalDateTime ldt) return ldt;
        if (val instanceof Timestamp ts) return ts.toLocalDateTime();
        if (val instanceof java.util.Date d) return d.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
        return null;
    }

    @Override
    public Map<String, Object> analyze(Long userId) {
        log.info("AI analizi başlatılıyor: userId={}", userId);
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new UserNotFoundException("Kullanıcı bulunamadı"));

            List<Expense> expenses = expenseRepository.findByUser(user);
            SummaryResponse summary = getSummary(userId);
            List<CategoryStatResponse> categoryStats = getCategoryStats(userId);
            List<DailyStatResponse> dailyStats = getDailyStats(userId, 30);

            List<Double> amounts = expenses.stream()
                    .filter(e -> e.getAmount() != null)
                    .map(Expense::getAmount)
                    .toList();

            List<Double> dailyAmounts = dailyStats.stream()
                    .map(DailyStatResponse::getTotal)
                    .toList();

            Map<String, Object> result = aiService.fullAnalyze(
                    summary.getTotalAmount(),
                    summary.getAverageDaily(),
                    summary.getTopCategory(),
                    categoryStats,
                    amounts,
                    dailyAmounts
            );

            log.info("AI analizi tamamlandı: userId={}", userId);
            return result;
        } catch (UserNotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.error("AI analizi sırasında hata oluştu: userId={}, error={}", userId, e.getMessage(), e);
            Map<String, Object> fallback = new HashMap<>();
            fallback.put("anomalies", List.of());
            fallback.put("budget_advice", Map.of("risk_level", "unknown", "advice", List.of(), "warnings", List.of("Analiz şu anda kullanılamıyor"), "savings_potential", 0.0));
            fallback.put("forecast", Map.of("forecast", List.of(), "trend", "unknown", "predicted_monthly", 0.0, "method", "none"));
            fallback.put("insights", List.of("Harcama analizi geçici olarak kullanılamıyor."));
            return fallback;
        }
    }
}


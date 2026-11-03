package com.yapayzeka.backend.services;

import com.yapayzeka.backend.controllers.dto.CategoryStatResponse;
import com.yapayzeka.backend.controllers.dto.DailyStatResponse;
import com.yapayzeka.backend.controllers.dto.ExpenseRequest;
import com.yapayzeka.backend.controllers.dto.SummaryResponse;
import com.yapayzeka.backend.entities.Expense;
import com.yapayzeka.backend.entities.User;

import java.util.List;
import java.util.Map;

public interface ExpenseService {

    // 🔹 Gün 4 — Harcama oluşturma (JWT email ile)
    Expense createExpense(ExpenseRequest request, String userEmail);

    // (opsiyonel – başka yerde kullanıyorsan kalsın)
    Expense saveExpense(Expense expense);

    // 🔹 Gün 3 — Tek harcama
    Expense getExpenseById(Long id);

    // 🔹 Gün 3 — Kullanıcının tüm harcamaları
    List<Expense> getMyExpenses(User user);

    // 🔹 Gün 5 — Kategoriye göre harcama
    List<Expense> getExpensesByCategoryAndUser(String category, User user);

    // 🔹 Gün 3/4 — Güncelleme
    Expense updateExpense(Long id, Expense expense);

    // 🔹 Gün 3/4 — Silme
    void deleteExpense(Long id);

    // (Eski istatistik – kullanıyorsan kalsın)
    Map<String, Long> getStatsByUser(User user);

    // ================================
    // 🟣 GÜN 6 — AKILLI ANALİZ (STAT)
    // ================================

    // 📊 Toplam, ortalama, en çok harcanan kategori
    SummaryResponse getSummary(Long userId);

    // 📊 Kategori bazlı toplam + yüzde
    List<CategoryStatResponse> getCategoryStats(Long userId);

    Map<String, Object> getInsights(Long userId);

    List<DailyStatResponse> getDailyStats(Long userId, int days);

    // 🤖 AI Analyze: Anomalies + Budget Advice + Forecasting
    Map<String, Object> analyze(Long userId);

    void deleteExpenseByUser(Long id, String email);
    int deleteAllByUser(String email);

    Map<String, Double> getCategoryStats(User user);

    // AI geri bildirim: kullanıcı AI tahminini kabul etti mi?
    void submitAiFeedback(Long expenseId, String userEmail, Boolean accepted, String correctedCategory);

    // AI doğruluk oranı raporu
    Map<String, Object> getAiAccuracy(User user);

}

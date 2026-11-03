package com.yapayzeka.backend.repositories;

import com.yapayzeka.backend.entities.Expense;
import com.yapayzeka.backend.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    // ========================
    // BASIC
    // ========================
    List<Expense> findByUser(User user);

    List<Expense> findByCategoryIgnoreCaseAndUser(String category, User user);

    Optional<Expense> findByIdAndUser(Long id, User user);

    // ✅ DELETE (USER SAFE)
    void deleteByIdAndUser(Long id, User user);

    // ========================
    // SUMMARY
    // ========================
    @Query("""
        SELECT COALESCE(SUM(e.amount), 0)
        FROM Expense e
        WHERE e.user = :user
    """)
    Double sumAmountByUser(@Param("user") User user);

    @Query("""
        SELECT MIN(e.createdAt), MAX(e.createdAt)
        FROM Expense e
        WHERE e.user = :user
    """)
    Object[] findDateRangeByUser(@Param("user") User user);

    // ✅ KATEGORİ DAĞILIMI (PIE / DONUT)
    @Query("""
        SELECT e.category, COALESCE(SUM(e.amount), 0)
        FROM Expense e
        WHERE e.user = :user
        GROUP BY e.category
    """)
    List<Object[]> sumAmountGroupByCategory(@Param("user") User user);

    // ========================
    // 📊 DAILY STATS (BAR CHART)
    // ========================
    @Query("""
        SELECT
            CAST(e.createdAt AS date),
            COALESCE(SUM(e.amount), 0)
        FROM Expense e
        WHERE e.user.id = :userId
          AND e.createdAt >= :startDate
        GROUP BY CAST(e.createdAt AS date)
        ORDER BY CAST(e.createdAt AS date)
    """)
    List<Object[]> sumDailyExpenses(
            @Param("userId") Long userId,
            @Param("startDate") LocalDateTime startDate
    );

    @Query("""
        SELECT e.category, COALESCE(SUM(e.amount), 0)
        FROM Expense e
        WHERE e.user = :user
          AND e.createdAt >= :from
          AND e.createdAt < :to
        GROUP BY e.category
    """)
    List<Object[]> sumByCategoryBetween(
            @Param("user") User user,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to
    );
}

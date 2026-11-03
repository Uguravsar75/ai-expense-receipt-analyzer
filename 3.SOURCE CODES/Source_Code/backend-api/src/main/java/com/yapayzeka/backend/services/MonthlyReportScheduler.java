package com.yapayzeka.backend.services;

import com.yapayzeka.backend.controllers.dto.CategoryStatResponse;
import com.yapayzeka.backend.controllers.dto.SummaryResponse;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class MonthlyReportScheduler {

    private final UserRepository userRepository;
    private final ExpenseService expenseService;
    private final JavaMailSender mailSender;

    // Her ayın 1'i saat 09:00'da çalışır
    @Scheduled(cron = "0 0 9 1 * *")
    public void sendMonthlyReports() {
        List<User> users = userRepository.findAll();
        int sent = 0;

        for (User user : users) {
            if (!user.isEmailVerified()) continue;
            try {
                sendReportToUser(user);
                sent++;
            } catch (Exception e) {
                log.warn("Aylık rapor gönderilemedi: {} — {}", user.getEmail(), e.getMessage());
            }
        }
        log.info("Aylık rapor gönderildi: {}/{} kullanıcı", sent, users.size());
    }

    private void sendReportToUser(User user) throws Exception {
        SummaryResponse summary = expenseService.getSummary(user.getId());
        if (summary.getTotalAmount() == 0) return; // Harcaması yoksa email gönderme

        List<CategoryStatResponse> categories = expenseService.getCategoryStats(user.getId());

        String lastMonth = LocalDate.now().minusMonths(1)
                .getMonth().getDisplayName(TextStyle.FULL, Locale.of("tr"));

        StringBuilder catRows = new StringBuilder();
        for (CategoryStatResponse c : categories) {
            catRows.append("""
                <tr>
                  <td style="padding:6px 12px;border-bottom:1px solid #f0f0f0;">%s</td>
                  <td style="padding:6px 12px;border-bottom:1px solid #f0f0f0;text-align:right;
                             font-weight:bold;">%.2f ₺</td>
                  <td style="padding:6px 12px;border-bottom:1px solid #f0f0f0;text-align:right;
                             color:#888;">%.1f%%</td>
                </tr>
                """.formatted(c.getCategory(), c.getTotal(), c.getPercentage()));
        }

        String html = """
            <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px;
                        border:1px solid #e0e0e0;border-radius:12px;">
              <h2 style="color:#5c35cc;">📊 %s Ayı Harcama Raporu</h2>
              <p>Merhaba <strong>%s</strong>,</p>
              <p>Geçen aya ait harcama özetiniz aşağıdadır:</p>

              <div style="background:#f7f4ff;border-radius:8px;padding:16px;margin:16px 0;
                          display:flex;gap:24px;text-align:center;">
                <div style="flex:1;">
                  <div style="font-size:24px;font-weight:bold;color:#5c35cc;">%.2f ₺</div>
                  <div style="color:#888;font-size:13px;">Toplam Harcama</div>
                </div>
                <div style="flex:1;">
                  <div style="font-size:24px;font-weight:bold;color:#5c35cc;">%.2f ₺</div>
                  <div style="color:#888;font-size:13px;">Günlük Ortalama</div>
                </div>
                <div style="flex:1;">
                  <div style="font-size:18px;font-weight:bold;color:#5c35cc;">%s</div>
                  <div style="color:#888;font-size:13px;">En Çok Harcanan</div>
                </div>
              </div>

              <h3 style="color:#444;margin-top:20px;">Kategori Dağılımı</h3>
              <table style="width:100%%;border-collapse:collapse;">
                <thead>
                  <tr style="background:#f0ebff;">
                    <th style="padding:8px 12px;text-align:left;color:#5c35cc;">Kategori</th>
                    <th style="padding:8px 12px;text-align:right;color:#5c35cc;">Tutar</th>
                    <th style="padding:8px 12px;text-align:right;color:#5c35cc;">Pay</th>
                  </tr>
                </thead>
                <tbody>%s</tbody>
              </table>

              <p style="margin-top:20px;color:#888;font-size:12px;">
                Bu email aylık otomatik raporunuzdur.<br>
                Detaylı analiz için uygulamayı açın.
              </p>
            </div>
            """.formatted(
                lastMonth,
                user.getName(),
                summary.getTotalAmount(),
                summary.getAverageDaily(),
                summary.getTopCategory(),
                catRows
        );

        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setFrom(System.getenv().getOrDefault("MAIL_USERNAME", "noreply@example.com"));
        helper.setTo(user.getEmail());
        helper.setSubject("📊 " + lastMonth + " Ayı Harcama Raporu");
        helper.setText(html, true);
        mailSender.send(message);
        log.info("Aylık rapor gönderildi: {}", user.getEmail());
    }
}

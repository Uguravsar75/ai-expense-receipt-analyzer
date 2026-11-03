package com.yapayzeka.backend.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Value("${app.frontend.url:http://localhost:3000}")
    private String frontendUrl;

    @Value("${app.backend.url:http://localhost:8080/api}")
    private String backendUrl;

    // ========================
    // EMAIL DOĞRULAMA
    // ========================
    public void sendVerificationEmail(String toEmail, String userName, String token) {
        String subject = "📧 Email Adresinizi Doğrulayın — Fatura Analiz";
        String verifyUrl = backendUrl + "/auth/verify-email-link?token=" + token;

        String html = """
            <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px;border:1px solid #e0e0e0;border-radius:12px;">
              <h2 style="color:#5c35cc;">📊 Fatura & Harcama Analiz</h2>
              <p>Merhaba <strong>%s</strong>,</p>
              <p>Hesabınızı aktifleştirmek için aşağıdaki butona tıklayın:</p>
              <a href="%s"
                 style="display:inline-block;margin:16px 0;padding:12px 24px;background:#5c35cc;color:#fff;
                        text-decoration:none;border-radius:8px;font-weight:bold;">
                Email Adresimi Doğrula
              </a>
              <p style="color:#888;font-size:12px;">Bu link 24 saat geçerlidir.<br>
              Eğer siz kayıt olmadıysanız bu emaili görmezden gelin.</p>
              <hr style="border:none;border-top:1px solid #eee;margin:16px 0;">
              <p style="color:#aaa;font-size:11px;">Doğrulama kodu: <code>%s</code></p>
            </div>
            """.formatted(userName, verifyUrl, token);

        sendHtml(toEmail, subject, html);
    }

    // ========================
    // ŞİFRE SIFIRLAMA
    // ========================
    public void sendPasswordResetEmail(String toEmail, String userName, String token) {
        String subject = "🔐 Şifre Sıfırlama İsteği — Fatura Analiz";

        String html = """
            <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px;border:1px solid #e0e0e0;border-radius:12px;">
              <h2 style="color:#5c35cc;">🔐 Şifre Sıfırlama</h2>
              <p>Merhaba <strong>%s</strong>,</p>
              <p>Şifrenizi sıfırlamak için aşağıdaki kodu uygulamaya girin:</p>
              <div style="text-align:center;margin:20px 0;">
                <span style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#5c35cc;
                             background:#f0ebff;padding:12px 24px;border-radius:8px;">
                  %s
                </span>
              </div>
              <p style="color:#888;font-size:12px;">Bu kod <strong>15 dakika</strong> geçerlidir.<br>
              Eğer siz şifre sıfırlama isteği yapmadıysanız bu emaili görmezden gelin.</p>
            </div>
            """.formatted(userName, token);

        sendHtml(toEmail, subject, html);
    }

    // ========================
    // YARDIMCI
    // ========================
    private void sendHtml(String to, String subject, String html) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Email gönderildi: {} → {}", subject, to);
        } catch (Exception e) {
            // Spring MailException (RuntimeException) veya MessagingException — ikisini de yakala
            log.error("Email gönderilemedi: {} - {}", to, e.getMessage());
        }
    }
}

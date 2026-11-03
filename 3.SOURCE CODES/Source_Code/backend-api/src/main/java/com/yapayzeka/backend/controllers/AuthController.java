package com.yapayzeka.backend.controllers;

import com.yapayzeka.backend.controllers.dto.LoginRequest;
import com.yapayzeka.backend.controllers.dto.RegisterRequest;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.exception.InvalidInputException;
import com.yapayzeka.backend.exception.UnauthorizedException;
import com.yapayzeka.backend.exception.UserNotFoundException;
import com.yapayzeka.backend.repositories.UserRepository;
import com.yapayzeka.backend.security.JwtUtil;
import com.yapayzeka.backend.services.EmailService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    // ========================
    // REGISTER
    // ========================
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Kayıt isteği: {}", request.getEmail());

        // Gmail zorunluluğu
        if (!isGmail(request.getEmail())) {
            throw new InvalidInputException("Sadece Gmail adresleri (@gmail.com) kabul edilmektedir");
        }

        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new InvalidInputException("Bu email adresi zaten kayıtlı");
        }

        String verificationToken = UUID.randomUUID().toString();

        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setCreatedAt(LocalDateTime.now());
        user.setEmailVerified(false);
        user.setVerificationToken(verificationToken);

        userRepository.save(user);

        // Doğrulama emaili gönder
        emailService.sendVerificationEmail(user.getEmail(), user.getName(), verificationToken);

        log.info("Kullanıcı kaydedildi: {}", user.getEmail());
        log.info("=== DOĞRULAMA KODU [{}]: {} ===", user.getEmail(), verificationToken);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "message", "Kayıt başarılı! Gmail adresinize doğrulama linki gönderildi.",
                "email", user.getEmail(),
                "emailVerified", false,
                "devToken", verificationToken
        ));
    }

    // ========================
    // EMAIL DOĞRULAMA (Link ile — tarayıcıdan)
    // ========================
    @GetMapping("/verify-email-link")
    public ResponseEntity<String> verifyEmailLink(@RequestParam String token) {
        if (token == null || token.isBlank()) {
            return ResponseEntity.badRequest()
                    .header("Content-Type", "text/html;charset=UTF-8")
                    .body(htmlPage("Hata", "❌ Geçersiz doğrulama linki.", "#e53935"));
        }

        User user = userRepository.findByVerificationToken(token).orElse(null);

        if (user == null) {
            return ResponseEntity.badRequest()
                    .header("Content-Type", "text/html;charset=UTF-8")
                    .body(htmlPage("Hata", "❌ Geçersiz veya kullanılmış doğrulama linki.", "#e53935"));
        }

        user.setEmailVerified(true);
        user.setVerificationToken(null);
        userRepository.save(user);

        log.info("Email doğrulandı (link): {}", user.getEmail());
        return ResponseEntity.ok()
                .header("Content-Type", "text/html;charset=UTF-8")
                .body(successPage(user.getEmail()));
    }

    private String successPage(String email) {
        return """
            <!DOCTYPE html>
            <html><head><meta charset="UTF-8"><title>Email Doğrulandı</title></head>
            <body style="font-family:Arial,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#f5f3ff;">
              <div style="text-align:center;padding:48px 40px;border-radius:20px;background:white;box-shadow:0 4px 24px rgba(92,53,204,0.12);max-width:420px;width:90%%;">
                <div style="font-size:56px;margin-bottom:16px;">✅</div>
                <h2 style="color:#5c35cc;margin:0 0 12px;">Email Doğrulandı!</h2>
                <p style="color:#555;margin:0 0 8px;">%s</p>
                <p style="color:#888;font-size:14px;margin:0 0 32px;">Hesabınız başarıyla aktifleştirildi.<br>Uygulamaya dönüp giriş yapabilirsiniz.</p>
                <div style="background:#f0ebff;border-radius:12px;padding:16px;font-size:14px;color:#5c35cc;">
                  Bu pencereyi kapatıp uygulamaya dönebilirsiniz.
                </div>
              </div>
            </body></html>
            """.formatted(email);
    }

    private String htmlPage(String title, String message, String color) {
        return """
            <!DOCTYPE html>
            <html><head><meta charset="UTF-8"><title>%s</title></head>
            <body style="font-family:Arial,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#f5f3ff;">
              <div style="text-align:center;padding:40px;border-radius:16px;background:white;box-shadow:0 4px 20px rgba(0,0,0,0.1);max-width:400px;">
                <h2 style="color:%s;">%s</h2>
                <p style="color:#555;">%s</p>
              </div>
            </body></html>
            """.formatted(title, color, title, message);
    }

    // ========================
    // EMAIL DOĞRULAMA (API — uygulamadan)
    // ========================
    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@RequestBody Map<String, String> body) {
        String token = body.getOrDefault("token", "").trim();

        if (token.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Doğrulama kodu boş olamaz"));
        }

        User user = userRepository.findByVerificationToken(token)
                .orElse(null);

        if (user == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Geçersiz veya süresi dolmuş doğrulama kodu"));
        }

        user.setEmailVerified(true);
        user.setVerificationToken(null);
        userRepository.save(user);

        log.info("Email doğrulandı: {}", user.getEmail());
        return ResponseEntity.ok(Map.of(
                "message", "Email adresiniz başarıyla doğrulandı! Giriş yapabilirsiniz.",
                "email", user.getEmail()
        ));
    }

    // ========================
    // EMAIL DOĞRULAMA YENİDEN GÖNDER
    // ========================
    @PostMapping("/resend-verification")
    public ResponseEntity<?> resendVerification(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "").trim();

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Bu email ile kayıtlı kullanıcı bulunamadı"));
        }
        if (user.isEmailVerified()) {
            return ResponseEntity.ok(Map.of("message", "Email adresiniz zaten doğrulanmış"));
        }

        String newToken = UUID.randomUUID().toString();
        user.setVerificationToken(newToken);
        userRepository.save(user);

        emailService.sendVerificationEmail(user.getEmail(), user.getName(), newToken);

        return ResponseEntity.ok(Map.of("message", "Doğrulama emaili tekrar gönderildi"));
    }

    // ========================
    // LOGIN
    // ========================
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        log.info("Giriş denemesi: {}", request.getEmail());

        // Gmail zorunluluğu
        if (!isGmail(request.getEmail())) {
            throw new InvalidInputException("Sadece Gmail adresleri (@gmail.com) ile giriş yapılabilir");
        }

        return userRepository.findByEmail(request.getEmail())
                .map(user -> {
                    if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                        throw new UnauthorizedException("Geçersiz email veya şifre");
                    }

                    if (!user.isEmailVerified()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                                Map.of(
                                        "message", "Email adresiniz henüz doğrulanmamış. Lütfen Gmail'inizi kontrol edin.",
                                        "emailVerified", false,
                                        "email", user.getEmail()
                                )
                        );
                    }

                    String token = JwtUtil.generateToken(user.getId(), user.getEmail());

                    log.info("Giriş başarılı: {}", user.getEmail());
                    return ResponseEntity.ok(Map.of(
                            "token", token,
                            "userId", user.getId(),
                            "email", user.getEmail(),
                            "name", user.getName(),
                            "emailVerified", true
                    ));
                })
                .orElseGet(() -> {
                    throw new UserNotFoundException("Kullanıcı bulunamadı");
                });
    }

    // ========================
    // ŞİFREMİ UNUTTUM
    // ========================
    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "").trim();

        if (!isGmail(email)) {
            return ResponseEntity.badRequest().body(
                    Map.of("message", "Sadece Gmail adresleri (@gmail.com) desteklenmektedir"));
        }

        User user = userRepository.findByEmail(email).orElse(null);

        // Güvenlik: kullanıcı olmasa da aynı mesajı göster
        if (user == null) {
            log.warn("Şifre sıfırlama isteği - kullanıcı bulunamadı: {}", email);
            return ResponseEntity.ok(Map.of(
                    "message", "Eğer bu email kayıtlıysa, şifre sıfırlama kodu gönderildi"));
        }

        // 6 haneli kod oluştur
        String resetCode = String.valueOf((int) (Math.random() * 900000) + 100000);
        user.setResetToken(resetCode);
        user.setResetTokenExpiry(LocalDateTime.now().plusMinutes(15));
        userRepository.save(user);

        emailService.sendPasswordResetEmail(user.getEmail(), user.getName(), resetCode);

        log.info("Şifre sıfırlama kodu gönderildi: {}", email);
        return ResponseEntity.ok(Map.of(
                "message", "Şifre sıfırlama kodu Gmail adresinize gönderildi",
                "email", email
        ));
    }

    // ========================
    // ŞİFRE SIFIRLAMA
    // ========================
    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "").trim();
        String code = body.getOrDefault("code", "").trim();
        String newPassword = body.getOrDefault("newPassword", "").trim();

        if (email.isEmpty() || code.isEmpty() || newPassword.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Tüm alanlar doldurulmalı"));
        }
        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("message", "Şifre en az 6 karakter olmalı"));
        }

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null || user.getResetToken() == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Geçersiz istek"));
        }

        if (!user.getResetToken().equals(code)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Sıfırlama kodu yanlış"));
        }

        if (user.getResetTokenExpiry() == null
                || LocalDateTime.now().isAfter(user.getResetTokenExpiry())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Sıfırlama kodunun süresi dolmuş. Yeniden isteyin."));
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        user.setResetToken(null);
        user.setResetTokenExpiry(null);
        userRepository.save(user);

        log.info("Şifre sıfırlandı: {}", email);
        return ResponseEntity.ok(Map.of("message", "Şifreniz başarıyla güncellendi! Giriş yapabilirsiniz."));
    }

    // ========================
    // YARDIMCI
    // ========================
    private boolean isGmail(String email) {
        return email != null && email.toLowerCase().endsWith("@gmail.com");
    }
}

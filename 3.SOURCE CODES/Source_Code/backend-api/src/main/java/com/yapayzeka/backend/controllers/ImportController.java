package com.yapayzeka.backend.controllers;

import com.yapayzeka.backend.controllers.dto.ImportResultResponse;
import com.yapayzeka.backend.controllers.dto.ImportResultResponse.ImportedExpenseDto;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.repositories.UserRepository;
import com.yapayzeka.backend.services.AIService;
import com.yapayzeka.backend.services.impl.ImportServiceImpl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/import")
@RequiredArgsConstructor
@Slf4j
public class ImportController {

    private final ImportServiceImpl importService;
    private final UserRepository userRepository;
    private final AIService aiService;

    /**
     * POST /api/import/upload
     * Dosyayı parse eder, AI ile kategoriler, ama KAYDETMEZ (önizleme).
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadFile(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Dosya boş.");
        }

        String filename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().toLowerCase() : "";
        if (!filename.endsWith(".csv") && !filename.endsWith(".xlsx") && !filename.endsWith(".xls")) {
            return ResponseEntity.badRequest()
                    .body("Desteklenmeyen format. Lütfen .csv veya .xlsx yükleyin.");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        log.info("Önizleme başlatıldı: {} ({} bytes), user={}",
                filename, file.getSize(), user.getEmail());

        try {
            ImportResultResponse result = importService.importFile(file, user);
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            log.error("İçe aktarma hatası: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("Dosya işlenirken hata oluştu: " + e.getMessage());
        }
    }

    /**
     * POST /api/import/photo
     * Fotoğraf/görsel yükle → AI OCR ile analiz et → önizleme döndür (kaydetmez)
     */
    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadPhoto(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {

        if (authentication == null) return ResponseEntity.status(401).body("Unauthorized");
        if (file.isEmpty()) return ResponseEntity.badRequest().body("Dosya boş.");

        String filename = (file.getOriginalFilename() != null ? file.getOriginalFilename() : "").toLowerCase();
        if (!filename.endsWith(".jpg") && !filename.endsWith(".jpeg")
                && !filename.endsWith(".png") && !filename.endsWith(".webp")) {
            return ResponseEntity.badRequest().body("Desteklenmeyen format. JPG, PNG veya WEBP yükleyin.");
        }

        try {
            byte[] imageBytes = file.getBytes();
            Map<String, Object> result = aiService.analyzeReceiptImage(imageBytes, file.getOriginalFilename());

            if (!Boolean.TRUE.equals(result.get("success"))) {
                return ResponseEntity.internalServerError()
                        .body(result.getOrDefault("error", "Görsel analiz edilemedi"));
            }

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rawItems = (List<Map<String, Object>>) result.get("items");
            if (rawItems == null) rawItems = new ArrayList<>();

            String receiptDate = result.getOrDefault("date", "").toString();
            String receiptCategory = result.getOrDefault("category", "Diğer").toString();
            String merchantName = result.getOrDefault("merchant_name", "").toString();

            // Gemini item'larını ImportedExpenseDto formatına dönüştür
            // (Gemini "name" döndürür, confirm endpoint "description" bekler)
            List<Map<String, Object>> expenses = new ArrayList<>();
            for (Map<String, Object> item : rawItems) {
                Map<String, Object> dto = new java.util.HashMap<>();
                String name = item.getOrDefault("name", "").toString();
                dto.put("description", name.isBlank() ? merchantName : name);
                dto.put("amount", item.getOrDefault("amount", 0.0));
                dto.put("predictedCategory", receiptCategory);
                dto.put("finalCategory", receiptCategory);
                dto.put("date", receiptDate);
                expenses.add(dto);
            }

            return ResponseEntity.ok(Map.of(
                    "totalRows", expenses.size(),
                    "imported", expenses.size(),
                    "skipped", 0,
                    "errors", new ArrayList<>(),
                    "expenses", expenses,
                    "merchantName", merchantName,
                    "date", receiptDate,
                    "category", receiptCategory,
                    "engine", result.getOrDefault("engine", "unknown")
            ));
        } catch (Exception e) {
            log.error("Foto OCR hatası: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("Görsel işlenemedi: " + e.getMessage());
        }
    }

    /**
     * POST /api/import/confirm
     * Önizlenen harcamaları onaylayıp veritabanına kaydeder.
     */
    @PostMapping("/confirm")
    public ResponseEntity<?> confirmImport(
            @RequestBody List<ImportedExpenseDto> items,
            Authentication authentication) {

        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        if (items == null || items.isEmpty()) {
            return ResponseEntity.badRequest().body("Kaydedilecek harcama yok.");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        int saved = importService.confirmImport(items, user);
        return ResponseEntity.ok(Map.of("saved", saved, "message", saved + " harcama kaydedildi."));
    }
}

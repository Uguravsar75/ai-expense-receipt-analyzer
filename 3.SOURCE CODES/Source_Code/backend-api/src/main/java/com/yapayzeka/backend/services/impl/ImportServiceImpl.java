package com.yapayzeka.backend.services.impl;

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;
import com.yapayzeka.backend.controllers.dto.ImportResultResponse;
import com.yapayzeka.backend.controllers.dto.ImportResultResponse.ImportedExpenseDto;
import com.yapayzeka.backend.entities.Expense;
import com.yapayzeka.backend.entities.User;
import com.yapayzeka.backend.repositories.ExpenseRepository;
import com.yapayzeka.backend.services.AIService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class ImportServiceImpl {

    private final AIService aiService;
    private final ExpenseRepository expenseRepository;

    // Desteklenen CSV sütun başlıkları (küçük harf, Türkçe + İngilizce)
    private static final List<String> AMOUNT_HEADERS =
            List.of("tutar", "amount", "fiyat", "price", "miktar");
    private static final List<String> DESC_HEADERS =
            List.of("aciklama", "açıklama", "description", "desc", "tanim", "tanım", "not", "note");

    // ========================
    // CATEGORY NORMALIZATION
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
        return "Diğer";
    }

    // ========================
    // ANA METOD (preview only - does NOT save)
    // ========================
    public ImportResultResponse importFile(MultipartFile file, User user) throws IOException {
        String filename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().toLowerCase() : "";

        if (filename.endsWith(".xlsx") || filename.endsWith(".xls")) {
            return importExcel(file, user);
        } else if (filename.endsWith(".csv")) {
            return importCsv(file, user);
        } else {
            throw new IllegalArgumentException(
                    "Desteklenmeyen dosya türü. Lütfen CSV veya Excel (.xlsx) yükleyin.");
        }
    }

    // ========================
    // CSV IMPORT
    // ========================
    private ImportResultResponse importCsv(MultipartFile file, User user) throws IOException {
        List<String[]> rows;
        try (CSVReader reader = new CSVReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            rows = reader.readAll();
        } catch (CsvException e) {
            throw new IOException("CSV dosyası okunamadı: " + e.getMessage());
        }

        if (rows.isEmpty()) {
            return emptyResult("CSV dosyası boş.");
        }

        // İlk satır başlık
        String[] headers = rows.get(0);
        int amountIdx = findColumnIndex(headers, AMOUNT_HEADERS);
        int descIdx = findColumnIndex(headers, DESC_HEADERS);

        if (amountIdx == -1) {
            return emptyResult(
                    "Tutar sütunu bulunamadı. Sütun adı 'tutar', 'amount' veya 'fiyat' olmalı.");
        }

        List<RawRow> rawRows = new ArrayList<>();
        for (int i = 1; i < rows.size(); i++) {
            String[] row = rows.get(i);
            if (row.length == 0) continue;
            String amountStr = amountIdx < row.length ? row[amountIdx].trim() : "";
            String desc = descIdx != -1 && descIdx < row.length ? row[descIdx].trim() : "";
            rawRows.add(new RawRow(amountStr, desc, i + 1));
        }

        return processRows(rawRows, user);
    }

    // ========================
    // EXCEL IMPORT
    // ========================
    private ImportResultResponse importExcel(MultipartFile file, User user) throws IOException {
        try (Workbook workbook = new XSSFWorkbook(file.getInputStream())) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet.getPhysicalNumberOfRows() == 0) {
                return emptyResult("Excel dosyası boş.");
            }

            Row headerRow = sheet.getRow(0);
            if (headerRow == null) return emptyResult("Başlık satırı bulunamadı.");

            int amountIdx = findExcelColumnIndex(headerRow, AMOUNT_HEADERS);
            int descIdx = findExcelColumnIndex(headerRow, DESC_HEADERS);

            if (amountIdx == -1) {
                return emptyResult(
                        "Tutar sütunu bulunamadı. Sütun adı 'tutar', 'amount' veya 'fiyat' olmalı.");
            }

            List<RawRow> rawRows = new ArrayList<>();
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                String amountStr = getCellString(row, amountIdx);
                String desc = descIdx != -1 ? getCellString(row, descIdx) : "";
                if (!amountStr.isBlank()) {
                    rawRows.add(new RawRow(amountStr, desc, i + 1));
                }
            }

            return processRows(rawRows, user);
        }
    }

    // ========================
    // SATIR İŞLEME + AI (KAYDETMEZ - önizleme)
    // ========================
    private ImportResultResponse processRows(List<RawRow> rawRows, User user) {
        List<ImportedExpenseDto> imported = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        int skipped = 0;

        for (RawRow raw : rawRows) {
            Double amount;
            try {
                String cleaned = raw.amountStr
                        .replace("₺", "").replace("TL", "")
                        .replace(",", ".").trim();
                amount = Double.parseDouble(cleaned);
                if (amount <= 0) {
                    errors.add(String.format("Satır %d: Tutar 0'dan büyük olmalı (%s)",
                            raw.rowNum, raw.amountStr));
                    skipped++;
                    continue;
                }
                if (amount > 10_000_000) {
                    errors.add(String.format("Satır %d: Tutar çok büyük (%s)",
                            raw.rowNum, raw.amountStr));
                    skipped++;
                    continue;
                }
            } catch (NumberFormatException e) {
                errors.add(String.format("Satır %d: Geçersiz tutar '%s'",
                        raw.rowNum, raw.amountStr));
                skipped++;
                continue;
            }

            // AI kategori tahmini
            String predicted = "Diğer";
            try {
                String text = raw.description.isBlank() ? "harcama" : raw.description;
                String aiResult = aiService.predictCategory(text);
                if (aiResult != null && !aiResult.isBlank() && !"unknown".equalsIgnoreCase(aiResult)) {
                    predicted = normalizeCategory(aiResult);
                }
            } catch (Exception e) {
                log.warn("Satır {} için AI tahmini başarısız: {}", raw.rowNum, e.getMessage());
            }

            imported.add(new ImportedExpenseDto(
                    amount, raw.description, predicted, predicted, null));

            log.debug("Önizleme: {}₺ → {} ({})", amount, predicted, raw.description);
        }

        log.info("Önizleme tamamlandı: {} satır, {} atlandı", imported.size(), skipped);

        return new ImportResultResponse(
                rawRows.size(), imported.size(), skipped, errors, imported);
    }

    // ========================
    // ONAY SONRASI KAYDET
    // ========================
    public int confirmImport(List<ImportedExpenseDto> items, User user) {
        int saved = 0;
        for (ImportedExpenseDto item : items) {
            if (item.getAmount() == null || item.getAmount() <= 0) continue;
            Expense expense = new Expense();
            expense.setAmount(item.getAmount());
            expense.setDescription(item.getDescription() == null || item.getDescription().isBlank()
                    ? null : item.getDescription());
            expense.setCategory(item.getFinalCategory() != null ? item.getFinalCategory() : "Diğer");
            expense.setPredictedCategory(item.getPredictedCategory());
            expense.setAiAccepted(null);
            // Gemini'den gelen fiş tarihini kullan, yoksa şu anki zamanı kullan
            LocalDateTime createdAt = LocalDateTime.now();
            if (item.getDate() != null && !item.getDate().isBlank()) {
                try {
                    createdAt = LocalDate.parse(item.getDate()).atTime(LocalTime.NOON);
                } catch (Exception ignored) {}
            }
            expense.setCreatedAt(createdAt);
            expense.setUser(user);
            expenseRepository.save(expense);
            saved++;
        }
        log.info("Onaylanan içe aktarma: {} harcama kaydedildi", saved);
        return saved;
    }

    // ========================
    // YARDIMCI METODLAR
    // ========================
    private int findColumnIndex(String[] headers, List<String> candidates) {
        for (int i = 0; i < headers.length; i++) {
            String h = headers[i].trim().toLowerCase()
                    .replace("ı", "i").replace("ş", "s")
                    .replace("ğ", "g").replace("ç", "c")
                    .replace("ö", "o").replace("ü", "u");
            for (String candidate : candidates) {
                if (h.equals(candidate)) return i;
            }
        }
        return -1;
    }

    private int findExcelColumnIndex(Row headerRow, List<String> candidates) {
        String[] headers = new String[headerRow.getLastCellNum()];
        for (int i = 0; i < headerRow.getLastCellNum(); i++) {
            Cell cell = headerRow.getCell(i);
            headers[i] = cell != null ? cell.getStringCellValue() : "";
        }
        return findColumnIndex(headers, candidates);
    }

    private String getCellString(Row row, int idx) {
        Cell cell = row.getCell(idx);
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case NUMERIC -> String.valueOf(cell.getNumericCellValue());
            case STRING -> cell.getStringCellValue().trim();
            default -> "";
        };
    }

    private ImportResultResponse emptyResult(String error) {
        return new ImportResultResponse(0, 0, 0, List.of(error), List.of());
    }

    private record RawRow(String amountStr, String description, int rowNum) {}
}

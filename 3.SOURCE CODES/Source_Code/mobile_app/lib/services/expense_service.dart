import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../utils/api_constants.dart';
import '../auth/auth_storage.dart';
import '../models/expense.dart';
import '../models/expense_create_request.dart';
import '../models/daily_stat_model.dart';
import '../models/stats_models.dart';

class ExpenseService {
  // =========================
  // AUTH HEADERS
  // =========================
  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception("Token bulunamadı");
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // =========================
  // GET /expenses
  // =========================
  static Future<List<Expense>> getExpenses() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("Harcama listesi alınamadı (${response.statusCode})");
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Expense.fromJson(e)).toList();
  }

  // =========================
  // POST /expenses  — kaydedilen harcamayı döner (id için)
  // =========================
  static Future<Map<String, dynamic>?> createExpense(ExpenseCreateRequest req) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/expenses"),
      headers: await _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception("Harcama eklenemedi (${response.statusCode})");
  }

  // =========================
  // DELETE /expenses/{id}
  // =========================
  static Future<void> deleteExpense(int expenseId) async {
    final response = await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/expenses/$expenseId"),
      headers: await _headers(),
    );

    if (response.statusCode == 204) return;

    throw Exception("Harcama silinemedi (${response.statusCode})");
  }

  // =========================
  // GET /expenses/category/{category}
  // =========================
  static Future<List<Expense>> getExpensesByCategory(String category) async {
    final encoded = Uri.encodeComponent(category);

    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/category/$encoded"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Kategoriye göre liste alınamadı (${response.statusCode})",
      );
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Expense.fromJson(e)).toList();
  }

  // =========================
  // 📊 SUMMARY
  // GET /stats/summary
  // =========================
  static Future<SummaryModel> getSummary() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/summary"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("İstatistik özeti alınamadı (${response.statusCode})");
    }

    return SummaryModel.fromJson(jsonDecode(response.body));
  }

  // =========================
  // 📊 CATEGORY STATS
  // GET /stats/category
  // =========================
  static Future<List<CategoryStatModel>> getCategoryStats() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/category"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Kategori istatistikleri alınamadı (${response.statusCode})",
      );
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => CategoryStatModel.fromJson(e)).toList();
  }

  // =========================
  // 🧠 AI INSIGHTS
  // GET /stats/insights
  // =========================
  static Future<Map<String, dynamic>> getInsights() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/insights"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "AI yorumları alınamadı (${response.statusCode})",
      );
    }

    return jsonDecode(response.body);
  }

  // =========================
  // 📊 DAILY STATS
  // GET /stats/daily?days=7
  // =========================
  static Future<List<DailyStatModel>> getDailyStats({int days = 7}) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/daily?days=$days"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Günlük istatistik alınamadı (${response.statusCode})",
      );
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => DailyStatModel.fromJson(e)).toList();
  }

  // =========================
  // 🤖 AI CANLI KATEGORİ TAHMİNİ
  // POST /expenses/predict
  // =========================
  static Future<Map<String, dynamic>> predictCategory(String text) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/expenses/predict"),
      headers: await _headers(),
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {"category": "unknown"};
  }

  // =========================
  // 🤖 AI GERİ BİLDİRİM
  // PATCH /expenses/{id}/feedback
  // =========================
  static Future<void> submitFeedback(
    int expenseId, {
    required bool accepted,
    String? correctedCategory,
  }) async {
    final body = <String, dynamic>{"accepted": accepted};
    if (correctedCategory != null) body["correctedCategory"] = correctedCategory;

    await http.patch(
      Uri.parse("${ApiConstants.baseUrl}/expenses/$expenseId/feedback"),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  // =========================
  // 🤖 AI DOĞRULUK ORANI
  // GET /expenses/accuracy
  // =========================
  static Future<Map<String, dynamic>> getAiAccuracy() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/accuracy"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Doğruluk oranı alınamadı (${response.statusCode})");
  }

  // =========================
  // 🤖 AI ANALYZE
  // GET /stats/analyze
  // =========================
  static Future<Map<String, dynamic>> analyzeExpenses() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/analyze"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Harcama analizi alınamadı (${response.statusCode})",
      );
    }

    return jsonDecode(response.body);
  }

  // =========================
  // 📂 CSV / EXCEL İÇE AKTARMA
  // POST /import/upload
  // =========================
  static Future<Map<String, dynamic>> importFileBytes(
      List<int> bytes, String filename) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token bulunamadı");

    final ext = filename.split('.').last.toLowerCase();
    final contentType = ext == 'csv'
        ? MediaType('text', 'csv')
        : MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("${ApiConstants.baseUrl}/import/upload"),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: contentType));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return jsonDecode(body) as Map<String, dynamic>;
    throw Exception("İçe aktarma başarısız (${streamed.statusCode}): $body");
  }

  // =========================
  // FOTOĞRAF OCR ANALİZİ (bytes — web + mobil uyumlu)
  // POST /import/photo
  // =========================
  static Future<Map<String, dynamic>> uploadPhotoBytes(
      List<int> bytes, String filename) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token bulunamadı");

    final ext = filename.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("${ApiConstants.baseUrl}/import/photo"),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: contentType));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return jsonDecode(body) as Map<String, dynamic>;
    throw Exception("Fotoğraf analizi başarısız (${streamed.statusCode}): $body");
  }

  // =========================
  // TÜM HARCAMALARI SİL
  // DELETE /expenses/all
  // =========================
  static Future<void> deleteAllExpenses() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token bulunamadı");

    final response = await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/expenses/all"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception("Silinemedi (${response.statusCode}): ${response.body}");
    }
  }

  // =========================
  // GET /expenses/recurring
  // =========================
  static Future<Map<String, dynamic>> getRecurring() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/recurring"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Tekrarlayan harcamalar alınamadı (${response.statusCode})");
  }

  // =========================
  // GET /expenses/smart-analysis
  // =========================
  static Future<Map<String, dynamic>> getSmartAnalysis() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/smart-analysis"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Akıllı analiz alınamadı (${response.statusCode})");
  }

  // =========================
  // PUT /expenses/{id}
  // =========================
  static Future<void> updateExpense(int id,
      {required double amount,
      required String category,
      required String description}) async {
    final response = await http.put(
      Uri.parse("${ApiConstants.baseUrl}/expenses/$id"),
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'category': category,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Güncellenemedi (${response.statusCode}): ${response.body}");
    }
  }

  // =========================
  // DASHBOARD SUMMARY
  // GET /expenses/dashboard
  // =========================
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/dashboard"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Dashboard alınamadı (${response.statusCode})");
  }

  // =========================
  // ONAYLANAN HARCAMALARI KAYDET
  // POST /import/confirm
  // =========================
  static Future<int> confirmImport(List<Map<String, dynamic>> items) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token bulunamadı");

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/import/confirm"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(items),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['saved'] as int? ?? 0;
    }
    throw Exception("Kayıt başarısız (${response.statusCode}): ${response.body}");
  }

  // =========================
  // FULL AI ANALİZİ
  // GET /expenses/full-analysis
  // =========================
  static Future<Map<String, dynamic>> getFullAnalysis() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/expenses/full-analysis"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Full analiz alınamadı (${response.statusCode})");
  }

  // =========================
  // BÜTÇE TAVSIYELERI
  // GET /stats/smart-budget
  // =========================
  static Future<Map<String, dynamic>> getSmartBudget() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/smart-budget"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Akıllı bütçe alınamadı (${response.statusCode})");
  }

  // GET /expenses/budget-advice
  // =========================
  static Future<Map<String, dynamic>> getBudgetAdvice() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/stats/budget-advice"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Bütçe tavsiyesi alınamadı (${response.statusCode})");
  }

} // End of ExpenseService

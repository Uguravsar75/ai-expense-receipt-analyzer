import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import '../auth/auth_storage.dart';

class AuthService {
  // =========================
  // LOGIN
  // =========================
  static Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/login"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email.trim(),
        "password": password,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 403) {
      final bool emailVerified = data["emailVerified"] ?? false;
      if (!emailVerified) {
        throw EmailNotVerifiedException(
          email: data["email"] ?? email.trim(),
          message: data["message"] ?? "Email adresiniz doğrulanmamış.",
        );
      }
      throw Exception(data["message"] ?? "Erişim reddedildi");
    }

    if (response.statusCode != 200) {
      final String errorMsg = data["message"] ?? data["error"] ?? "Giriş başarısız (${response.statusCode})";
      throw Exception(errorMsg);
    }

    final String? token = data["token"];
    final int? userId = data["userId"];
    final String? emailFromApi = data["email"];
    final String? nameFromApi = data["name"];

    if (token == null || token.trim().isEmpty) {
      throw Exception("Token bulunamadı");
    }
    if (userId == null) {
      throw Exception("UserId bulunamadı");
    }

    await AuthStorage.saveToken(token);
    await AuthStorage.saveUserId(userId);
    if (emailFromApi != null && emailFromApi.trim().isNotEmpty) {
      await AuthStorage.saveEmail(emailFromApi);
    }
    if (nameFromApi != null && nameFromApi.trim().isNotEmpty) {
      await AuthStorage.saveName(nameFromApi);
    }
  }

  // =========================
  // REGISTER
  // =========================
  static Future<String> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/register"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final String errorMsg = data["message"] ?? data["error"] ?? "Kayıt başarısız (${response.statusCode})";
      throw Exception(errorMsg);
    }

    return data["email"] ?? email.trim();
  }

  static String? lastDevToken; // geliştirme: token'ı sakla

  static Future<Map<String, String>> registerWithToken(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/register"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final String errorMsg = data["message"] ?? data["error"] ?? "Kayıt başarısız (${response.statusCode})";
      throw Exception(errorMsg);
    }

    lastDevToken = data["devToken"] as String?;
    return {
      "email": data["email"] ?? email.trim(),
      "devToken": lastDevToken ?? "",
    };
  }

  // =========================
  // VERIFY EMAIL
  // =========================
  static Future<void> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/verify-email"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"token": token.trim()}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Doğrulama başarısız");
    }
  }

  // =========================
  // RESEND VERIFICATION
  // =========================
  static Future<void> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/resend-verification"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"email": email.trim()}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "İstek başarısız");
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/forgot-password"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"email": email.trim()}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "İstek başarısız");
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/auth/reset-password"),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email.trim(),
        "code": code.trim(),
        "newPassword": newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Şifre sıfırlama başarısız");
    }
  }
}

class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;
  const EmailNotVerifiedException({required this.email, required this.message});
}

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 20),

              const Text(
                "Şifre Sıfırla",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C35CC),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.email} adresine gönderilen 6 haneli kodu girin",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

              const SizedBox(height: 32),

              // 6-digit code
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "Sıfırlama Kodu",
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5C35CC), width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
              ),

              const SizedBox(height: 16),

              // New password
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Yeni Şifre",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5C35CC)),
                  suffixIcon: IconButton(
                    icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5C35CC), width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password
              TextField(
                controller: confirmController,
                obscureText: hideConfirm,
                decoration: InputDecoration(
                  labelText: "Yeni Şifre Tekrar",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5C35CC)),
                  suffixIcon: IconButton(
                    icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => hideConfirm = !hideConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5C35CC), width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C35CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _handleReset,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Şifremi Güncelle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReset() async {
    final code = codeController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (code.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack("Tüm alanlar doldurulmalı", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnack("Şifre en az 6 karakter olmalıdır", isError: true);
      return;
    }

    if (password != confirm) {
      _showSnack("Şifreler uyuşmuyor", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.resetPassword(
        email: widget.email,
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      _showSnack("Şifreniz başarıyla güncellendi!", isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }
}

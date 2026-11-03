import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  // ValueNotifier yerine sadece isLoading için setState, görünürlük için ayrı notifier
  final _hidePassword = ValueNotifier(true);
  final _hideConfirm = ValueNotifier(true);
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    _hidePassword.dispose();
    _hideConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Hesap Oluştur",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C35CC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Gmail adresinizle kayıt olun",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),

                // Ad Soyad
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Ad Soyad",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Ad Soyad boş olamaz" : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Gmail Adresi",
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: "ornek@gmail.com",
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Email boş olamaz";
                    if (!v.trim().toLowerCase().endsWith('@gmail.com')) return "Sadece @gmail.com kabul edilir";
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Şifre
                ValueListenableBuilder<bool>(
                  valueListenable: _hidePassword,
                  builder: (_, hide, __) => TextFormField(
                    controller: passwordController,
                    obscureText: hide,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => _hidePassword.value = !hide,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Şifre boş olamaz";
                      if (v.length < 6) return "En az 6 karakter olmalı";
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Şifre Tekrar
                ValueListenableBuilder<bool>(
                  valueListenable: _hideConfirm,
                  builder: (_, hide, __) => TextFormField(
                    controller: confirmController,
                    obscureText: hide,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: "Şifre Tekrar",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => _hideConfirm.value = !hide,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Şifre tekrarı boş olamaz";
                      if (v != passwordController.text) return "Şifreler uyuşmuyor";
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleRegister,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Kayıt Ol",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Zaten hesabın var mı? ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(color: Color(0xFF5C35CC), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      final result = await AuthService.registerWithToken(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: result["email"]!,
            devToken: result["devToken"],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

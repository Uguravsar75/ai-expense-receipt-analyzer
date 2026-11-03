import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _hidePassword = ValueNotifier(true);
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _hidePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C35CC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Fatura Analiz",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C35CC),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Gmail ile giriş yapın",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 40),

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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => _hidePassword.value = !hide,
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Şifre boş olamaz" : null,
                  ),
                ),

                // Şifremi Unuttum
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text(
                      "Şifremi Unuttum",
                      style: TextStyle(color: Color(0xFF5C35CC), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Giriş Yap",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Hesabın yok mu? ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        "Kayıt Ol",
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

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      await AuthService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on EmailNotVerifiedException catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: e.email)),
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

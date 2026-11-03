import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? devToken;

  const EmailVerificationScreen({super.key, required this.email, this.devToken});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isResending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C35CC).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF5C35CC), size: 44),
              ),

              const SizedBox(height: 28),

              const Text(
                "Email Doğrulama",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5C35CC)),
              ),

              const SizedBox(height: 16),

              Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                "adresinize doğrulama linki gönderildi.\n\nGmail'inizi açıp butona tıklayın — hesabınız otomatik aktifleşecek.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5C35CC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isResending ? null : _handleResend,
                  icon: isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5C35CC)),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF5C35CC)),
                  label: const Text(
                    "Linki Tekrar Gönder",
                    style: TextStyle(color: Color(0xFF5C35CC), fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                child: Text("Giriş ekranına dön", style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleResend() async {
    setState(() => isResending = true);
    try {
      await AuthService.resendVerification(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Doğrulama linki tekrar gönderildi"), backgroundColor: Colors.green[700]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red[700]),
      );
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }
}

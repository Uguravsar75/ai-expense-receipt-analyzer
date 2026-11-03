import 'package:flutter/material.dart';

class CategoryConstants {
  // Backend'den gelen kategori adları (normalizeCategory çıktısı)
  static const List<String> allCategories = [
    'Market',
    'Yeme & İçme',
    'Faturalar',
    'Ulaşım',
    'Kira & Ev',
    'Sağlık',
    'Eğlence',
    'Giyim',
    'Eğitim',
    'Diğer',
  ];

  static List<String> trList() => allCategories;

  // Türkçe ad → backend kodu (artık aynı değer, backward-compat için)
  static String trToCode(String tr) => tr;

  // Kategori adından Türkçe görüntü adı (zaten Türkçe, fallback Diğer)
  static String toTr(String? code) {
    if (code == null || code.trim().isEmpty) return 'Diğer';
    final key = code.trim();
    if (allCategories.contains(key)) return key;
    // eski İngilizce kodlar için fallback
    switch (key.toUpperCase()) {
      case 'FOOD': return 'Yeme & İçme';
      case 'TRANSPORT': return 'Ulaşım';
      case 'EDUCATION': return 'Eğitim';
      case 'SHOPPING': return 'Market';
      case 'HEALTH': return 'Sağlık';
      default: return 'Diğer';
    }
  }

  static Color colorOf(String? code) {
    switch (toTr(code)) {
      case 'Market':      return const Color(0xFF43A047);
      case 'Yeme & İçme': return const Color(0xFFFF7043);
      case 'Faturalar':   return const Color(0xFFFFB300);
      case 'Ulaşım':      return const Color(0xFF1E88E5);
      case 'Kira & Ev':   return const Color(0xFF8E24AA);
      case 'Sağlık':      return const Color(0xFFE53935);
      case 'Eğlence':     return const Color(0xFFEC407A);
      case 'Giyim':       return const Color(0xFF00ACC1);
      case 'Eğitim':      return const Color(0xFF3949AB);
      default:            return const Color(0xFF757575);
    }
  }

  static IconData iconOf(String? code) {
    switch (toTr(code)) {
      case 'Market':      return Icons.shopping_cart;
      case 'Yeme & İçme': return Icons.restaurant;
      case 'Faturalar':   return Icons.receipt_long;
      case 'Ulaşım':      return Icons.directions_car;
      case 'Kira & Ev':   return Icons.home;
      case 'Sağlık':      return Icons.local_hospital;
      case 'Eğlence':     return Icons.movie;
      case 'Giyim':       return Icons.checkroom;
      case 'Eğitim':      return Icons.school;
      default:            return Icons.category;
    }
  }
}

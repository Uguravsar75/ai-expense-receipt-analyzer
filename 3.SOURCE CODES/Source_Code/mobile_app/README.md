# 📱 Fatura & Harcama Analiz — Mobil Uygulama (Flutter)

Yapay Zeka Destekli Fatura ve Harcama Analiz Sistemi'nin Flutter ile geliştirilmiş istemci uygulamasıdır.

## Özellikler
- **JWT Tabanlı Kimlik Doğrulama:** Kayıt, Gmail doğrulama ve şifre sıfırlama.
- **Akıllı Harcama Ekleme:** Açıklama yazarken canlı AI kategori tahmini ve geri bildirim (Onay/Red).
- **Fiş/Fatura Tarama & Dosya Aktarımı:** Kamera/Galeri üzerinden fiş okuma (OCR) ve CSV/Excel toplu içe aktarma.
- **İstatistikler ve AI Analiz Ekranı:** Kategori pasta grafiği (`fl_chart`), son 7 günlük sütun grafiği, anomali uyarıları, ARIMA aylık tahminleme ve kategori bazlı bütçe hedefleri.
- **Çoklu Dil ve Tema:** 5 dil (TR, EN, DE, FR, AR) ve Açık/Koyu tema desteği.

## Çalıştırma
```bash
flutter pub get
flutter run
```
> Not: Android Emülatör üzerinde çalışırken Backend adresi otomatik olarak `http://10.0.2.2:8080/api`, iOS/Masaüstü/Web üzerinde `http://localhost:8080/api` olarak yapılandırılır (`lib/utils/api_constants.dart`).

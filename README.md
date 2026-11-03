# 📊 Yapay Zeka Destekli Fatura ve Harcama Analiz Sistemi

Bu proje, **Düzce Üniversitesi Bilgisayar Mühendisliği Bölümü** bitirme tezi kapsamında geliştirilmiş; kullanıcıların kişisel harcamalarını ve fiş/faturalarını yapay zeka desteğiyle sınıflandıran, analiz eden, anomali tespiti yapan ve geleceğe yönelik bütçe tahminlemesi sunan uçtan uca (full-stack) bir mobil ve mikroservis uygulamasıdır.

- **Geliştirici:** Uğur Avşar
- **Üniversite / Bölüm:** Düzce Üniversitesi — Bilgisayar Mühendisliği
- **Yıl:** 2026

---

## 📁 Proje Klasör Yapısı

```text
Thesis_proje_Ugur_Avsar/
├── 1.REPORT/
│   └── Assignment_Report_Ugur_Avsar.pdf       # Bitirme Tezi Raporu
├── 2.PRESENTATIONS/
│   ├── 01_Term_Beginning_Presentation.pdf     # Dönem Başı Sunumu
│   ├── 02_Literature_Review_Presentation.pdf  # Literatür Taraması Sunumu
│   ├── 03_Design_and_Development_Presentation.pdf
│   ├── 04_Result_and_Demo_Presentation.pdf
│   └── 05_Final_Defense_Presentation.pdf      # Final Savunma Sunumu
├── 3.SOURCE CODES/
│   └── Source_Code/
│       ├── backend-api/                       # Spring Boot 3.3 (Java 21) REST API
│       ├── ai-service/                        # Python FastAPI Yapay Zeka & OCR Servisi
│       ├── mobile_app/                        # Flutter Çoklu Dil & Tema Destekli Mobil Uygulama
│       ├── docker-compose.yml                 # Tüm servisler için Docker Orkestrasyonu
│       ├── init-db.sql                        # PostgreSQL Veritabanı Şeması
│       ├── start-all.ps1                      # Tek tıkla tüm servisleri başlatma betiği
│       └── stop.ps1                           # Servisleri durdurma betiği
├── 4.APPLICATION FILES/
│   └── Application/
│       ├── FaturaAnaliz.apk                   # Android Kurulum Paketi (APK)
│       └── application_video.mp4              # Uygulama Tanıtım ve Demo Videosu
└── 5.DOCUMENTS/
    └── Documents/
        ├── Installation_Instructions.pdf      # Kurulum Kılavuzu
        ├── User_Manual.pdf                    # Kullanıcı Kılavuzu
        └── License_Information.txt            # Lisans Bilgileri (MIT)
```

---

## 🚀 Temel Özellikler

1. **🤖 Yapay Zeka ile Otomatik Kategori Tahmini (NLP):**
   - Harcama açıklamalarından `TF-IDF Vectorizer` ve `Logistic Regression` modelleriyle 10 farklı kategoride (*Market, Yeme & İçme, Faturalar, Ulaşım, Kira & Ev, Sağlık, Eğlence, Giyim, Eğitim, Diğer*) anlık tahmin ve kullanıcı geri bildirimi (feedback loop) ile doğruluk takibi.
2. **📸 Akıllı Fiş / Fatura Okuma (Gemini Vision & EasyOCR):**
   - Kamera veya galeriden yüklenen fiş fotoğraflarından işyeri adı, tarih, kalemler ve toplam tutarı **Google Gemini 2.5 Flash Vision** ile (veya çevrimdışı durumda **EasyOCR** fallback mekanizmasıyla) otomatik çıkarma.
3. **📈 Zaman Serisi Harcama Tahminleme (ARIMA):**
   - `statsmodels` ARIMA modeli ve hareketli ortalama (Moving Average) ile gelecek dönem ve ay sonu harcama projeksiyonu.
4. **🚨 Anomali Tespiti (Isolation Forest):**
   - Kullanıcının olağan harcama alışkanlıklarının dışına çıkan standart dışı harcamaları `scikit-learn` `IsolationForest` algoritmasıyla tespit etme ve uyarma.
5. **💡 Akıllı Bütçe Danışmanı ve 3 Aylık Trend Analizi:**
   - Son 3 aylık kategori bazlı harcama eğilimlerini inceleyerek kategori bazında bütçe hedefleri ve tasarruf potansiyeli önerme.
6. **📂 Toplu Veri İçe Aktarma (CSV / Excel) & PDF Raporlama:**
   - Banka ekstresi veya harcama tablolarını `.csv` / `.xlsx` formatında önizlemeli olarak içe aktarma; aylık e-posta raporları ve uygulama içi PDF çıktı alma.
7. **🌍 Çoklu Dil ve Karanlık Tema (Dark Mode):**
   - Türkçe, İngilizce, Almanca, Fransızca ve Arapça dil desteği ile Material 3 açık/koyu tema desteği.

---

## 🛠️ Teknoloji Yığını

| Katman | Teknolojiler |
| :--- | :--- |
| **Mobil Uygulama** | Flutter (Dart 3.5+), Material 3, `fl_chart`, `http`, `shared_preferences`, `image_picker`, `pdf` |
| **Backend API** | Java 21, Spring Boot 3.3.5, Spring Security, JWT, Spring Data JPA, Spring Mail, Apache POI, OpenCSV, Swagger/OpenAPI |
| **AI & OCR Servisi** | Python 3.11+, FastAPI, scikit-learn, statsmodels (ARIMA), Google Gemini Vision (`google-genai`), EasyOCR |
| **Veritabanı & DevOps** | PostgreSQL 16, H2 Database (Geliştirme/Test), Docker & Docker Compose |

---

## ⚙️ Hızlı Kurulum ve Çalıştırma

### Seçenek 1: Docker Compose ile Çalıştırma (Önerilen)

```bash
cd "3.SOURCE CODES/Source_Code"
export GEMINI_API_KEY="sizin_gemini_api_anahtariniz"
docker compose up --build
```
- **Backend API & Swagger UI:** `http://localhost:8080/api/swagger-ui.html`
- **AI Servisi Dokümantasyonu:** `http://localhost:8000/docs`

### Seçenek 2: Manuel Çalıştırma

#### 1. AI Servisi (Port `8000`)
```bash
cd "3.SOURCE CODES/Source_Code/ai-service"
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env      # .env içine GEMINI_API_KEY değerinizi girin
python main.py
```

#### 2. Backend API (Port `8080`)
```bash
cd "3.SOURCE CODES/Source_Code/backend-api"
./mvnw spring-boot:run
```

#### 3. Mobil Uygulama (Flutter)
```bash
cd "3.SOURCE CODES/Source_Code/mobile_app"
flutter pub get
flutter run
```

---

## 📄 Lisans

Bu proje [MIT Lisansı](file:///Users/d3-11/Desktop/Thesis_proje_Ugur_Avsar/5.DOCUMENTS/Documents/License_Information.txt) altında lisanslanmıştır.


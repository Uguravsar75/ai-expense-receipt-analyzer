"""AI Expense Service - FastAPI backend for expense classification and analysis"""
import os
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from model import ExpenseClassifier
from anomaly import AnomalyDetector
from budgeting import BudgetAdvisor
from forecasting import ExpenseForecast
import gemini_service
import io, re

app = FastAPI(title="AI Expense Service", version="2.0.0")

clf = ExpenseClassifier()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# REQUEST / RESPONSE MODELLER
# =========================

class ExpenseText(BaseModel):
    text: str


class CategoryStat(BaseModel):
    category: str
    total: float
    percentage: float


class AnalyzeRequest(BaseModel):
    totalAmount: float
    averageDaily: float
    topCategory: str
    categoryStats: List[CategoryStat]


class AnalyzeResponse(BaseModel):
    insights: List[str]


class AnomalyRequest(BaseModel):
    amounts: List[float]
    contamination: Optional[float] = 0.1


class AnomalyItem(BaseModel):
    amount: float
    reason: str


class AnomalyResponse(BaseModel):
    anomalies: List[AnomalyItem]
    total_checked: int


class BudgetRequest(BaseModel):
    totalAmount: float
    averageDaily: float
    categoryStats: List[CategoryStat]


class BudgetResponse(BaseModel):
    advice: List[str]
    warnings: List[str]
    savings_potential: float
    risk_level: str


class ForecastRequest(BaseModel):
    dailyAmounts: List[float]
    forecastDays: Optional[int] = 7


class ForecastResponse(BaseModel):
    forecast: List[float]
    predicted_daily_avg: float
    predicted_monthly: float
    trend: str
    method: str


class FullAnalyzeRequest(BaseModel):
    totalAmount: float
    averageDaily: float
    topCategory: str
    categoryStats: List[CategoryStat]
    amounts: List[float]
    dailyAmounts: List[float]


class FullAnalyzeResponse(BaseModel):
    anomalies: List[AnomalyItem]
    budget_advice: BudgetResponse
    forecast: ForecastResponse
    insights: List[str]


# =========================
# HEALTH CHECK
# =========================

@app.get("/health")
def health():
    return {"status": "ok", "version": "2.0.0"}


# =========================
# KATEGORİ TAHMİNİ
# =========================

@app.post("/predict")
def predict_category(expense: ExpenseText):
    try:
        if not expense.text or not expense.text.strip():
            return {"category": "unknown"}
        category = clf.predict(expense.text)
        return {"category": category}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# ANALİZ & YORUM (eski endpoint - geriye dönük uyumluluk)
# =========================

@app.post("/analyze", response_model=AnalyzeResponse)
def analyze_expenses(req: AnalyzeRequest):
    try:
        insights = []

        if req.totalAmount <= 0 or len(req.categoryStats) == 0:
            return {"insights": ["Henüz harcama kaydı yok. Harcama ekledikten sonra analiz yapabilirim."]}

        insights.append(f"En çok harcadığın kategori: {req.topCategory}")

        for c in req.categoryStats:
            if c.percentage >= 40:
                insights.append(f"{c.category} harcamaların oldukça yüksek (%{c.percentage:.0f}).")

        if req.averageDaily >= 500:
            insights.append("Günlük ortalaman 500₺ üzeri. Aylık bütçe hedefi belirlemeni öneririm.")
        elif req.averageDaily >= 250:
            insights.append("Günlük ortalaman orta seviyede. Harcamalarını düzenli takip et.")
        else:
            insights.append("Günlük ortalaman düşük. Harcama kontrolün gayet iyi görünüyor.")

        return {"insights": insights}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# ANOMALİ TESPİTİ
# =========================

@app.post("/anomaly", response_model=AnomalyResponse)
def detect_anomalies(req: AnomalyRequest):
    try:
        if len(req.amounts) < 5:
            return AnomalyResponse(anomalies=[], total_checked=len(req.amounts))

        detector = AnomalyDetector(contamination=req.contamination)
        detector.fit(req.amounts)
        result = detector.predict(req.amounts)

        anomaly_items = []
        for idx in result.get("anomalies", []):
            amount = req.amounts[idx]
            reason = detector.get_anomaly_reason(amount, req.amounts)
            anomaly_items.append(AnomalyItem(amount=amount, reason=reason))

        return AnomalyResponse(
            anomalies=anomaly_items,
            total_checked=len(req.amounts)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# BÜTÇE DANIŞMANLIĞI
# =========================

@app.post("/budget", response_model=BudgetResponse)
def budget_advice(req: BudgetRequest):
    try:
        category_list = [
            {"category": c.category, "amount": c.total, "percentage": c.percentage}
            for c in req.categoryStats
        ]

        result = BudgetAdvisor.analyze(
            total_amount=req.totalAmount,
            average_daily=req.averageDaily,
            category_stats=category_list
        )

        return BudgetResponse(
            advice=result.get("advice", []),
            warnings=result.get("warnings", []),
            savings_potential=result.get("savings_potential", 0.0),
            risk_level=result.get("risk_level", "low")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# TAHMİNLEME (FORECASTING)
# =========================

@app.post("/forecast", response_model=ForecastResponse)
def forecast(req: ForecastRequest):
    try:
        if len(req.dailyAmounts) < 3:
            return ForecastResponse(
                forecast=[],
                predicted_daily_avg=0.0,
                predicted_monthly=0.0,
                trend="insufficient_data",
                method="none"
            )

        result = ExpenseForecast.arima_forecast(
            daily_expenses=req.dailyAmounts,
            forecast_days=req.forecastDays
        )

        trend = ExpenseForecast._analyze_trend(req.dailyAmounts)

        return ForecastResponse(
            forecast=result.get("forecast", []),
            predicted_daily_avg=result.get("predicted_daily_avg", 0.0),
            predicted_monthly=result.get("predicted_monthly", 0.0),
            trend=trend,
            method=result.get("method", "unknown")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# TAM ANALİZ (Anomali + Bütçe + Tahmin tek seferde)
# =========================

@app.post("/full-analyze", response_model=FullAnalyzeResponse)
def full_analyze(req: FullAnalyzeRequest):
    try:
        # 1. Anomali
        anomaly_items = []
        if len(req.amounts) >= 5:
            detector = AnomalyDetector(contamination=0.1)
            detector.fit(req.amounts)
            result = detector.predict(req.amounts)
            for idx in result.get("anomalies", []):
                amount = req.amounts[idx]
                reason = detector.get_anomaly_reason(amount, req.amounts)
                anomaly_items.append(AnomalyItem(amount=amount, reason=reason))

        # 2. Bütçe
        category_list = [
            {"category": c.category, "amount": c.total, "percentage": c.percentage}
            for c in req.categoryStats
        ]
        budget_result = BudgetAdvisor.analyze(
            total_amount=req.totalAmount,
            average_daily=req.averageDaily,
            category_stats=category_list
        )
        budget = BudgetResponse(
            advice=budget_result.get("advice", []),
            warnings=budget_result.get("warnings", []),
            savings_potential=budget_result.get("savings_potential", 0.0),
            risk_level=budget_result.get("risk_level", "low")
        )

        # 3. Tahmin
        forecast_result = {"forecast": [], "predicted_daily_avg": 0.0,
                           "predicted_monthly": 0.0, "method": "none"}
        if len(req.dailyAmounts) >= 3:
            forecast_result = ExpenseForecast.arima_forecast(
                daily_expenses=req.dailyAmounts,
                forecast_days=7
            )
        trend = ExpenseForecast._analyze_trend(req.dailyAmounts) if len(req.dailyAmounts) >= 2 else "insufficient_data"
        forecast_resp = ForecastResponse(
            forecast=forecast_result.get("forecast", []),
            predicted_daily_avg=forecast_result.get("predicted_daily_avg", 0.0),
            predicted_monthly=forecast_result.get("predicted_monthly", 0.0),
            trend=trend,
            method=forecast_result.get("method", "none")
        )

        # 4. Genel insights
        insights = []
        if req.totalAmount > 0:
            insights.append(f"En çok harcadığın kategori: {req.topCategory}")
        for c in req.categoryStats:
            if c.percentage >= 40:
                insights.append(f"{c.category} harcamaların toplam içindeki payı yüksek (%{c.percentage:.0f}).")
        if len(anomaly_items) > 0:
            insights.append(f"{len(anomaly_items)} adet anormal harcama tespit edildi.")
        if forecast_resp.predicted_monthly > 0:
            insights.append(f"Bu gidişle aylık tahmini harcaman: {forecast_resp.predicted_monthly:.0f}₺")

        return FullAnalyzeResponse(
            anomalies=anomaly_items,
            budget_advice=budget,
            forecast=forecast_resp,
            insights=insights
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# FOTO / GÖRSEL OCR ANALİZİ
# =========================

_ocr_reader = None

def get_ocr_reader():
    global _ocr_reader
    if _ocr_reader is None:
        import easyocr
        _ocr_reader = easyocr.Reader(['tr', 'en'], gpu=False, verbose=False)
    return _ocr_reader

def parse_amount_from_text(text: str) -> Optional[float]:
    """Metinden tutar bul: 125,50 veya 125.50 veya 125 TL gibi"""
    patterns = [
        r'TOPLAM[:\s]*(\d+[.,]\d{2})',
        r'TUTAR[:\s]*(\d+[.,]\d{2})',
        r'TOTAL[:\s]*(\d+[.,]\d{2})',
        r'(\d+[.,]\d{2})\s*TL',
        r'(\d+[.,]\d{2})\s*₺',
        r'(\d{2,6}[.,]\d{2})',
    ]
    text_upper = text.upper()
    for pattern in patterns:
        match = re.search(pattern, text_upper)
        if match:
            num = match.group(1).replace(',', '.')
            try:
                val = float(num)
                if 0 < val < 1_000_000:
                    return val
            except:
                pass
    return None

def extract_description_from_text(lines: list) -> str:
    """Fişten işyeri adı veya açıklama çıkar"""
    # İlk birkaç satır genellikle işyeri adıdır
    candidates = []
    for line in lines[:5]:
        line = line.strip()
        if len(line) > 3 and not re.match(r'^[\d\s.,₺TL]+$', line):
            candidates.append(line)
    return candidates[0] if candidates else "Fiş/Fatura"


def normalize_image_bytes(contents: bytes):
    """Normalize image bytes into an RGB numpy array acceptable by EasyOCR."""
    import numpy as np
    from PIL import Image

    try:
        image = Image.open(io.BytesIO(contents))
    except Exception as exc:
        raise ValueError(
            "Geçersiz görsel verisi. Lütfen JPEG, PNG veya WEBP formatında bir dosya yükleyin."
        ) from exc

    image = image.convert("RGB")
    image_np = np.asarray(image)

    if image_np.dtype != np.uint8:
        image_np = image_np.astype(np.uint8)

    return image_np


@app.post("/ocr-analyze")
async def ocr_analyze(file: UploadFile = File(...)):
    """
    Görsel yükle (JPG/PNG) → OCR ile metin çıkar → kategori + tutar tahmin et
    """
    try:
        contents = await file.read()

        # OCR ile metni çıkar
        reader = get_ocr_reader()
        image_np = normalize_image_bytes(contents)
        results = reader.readtext(image_np, detail=0, paragraph=False)

        if not results:
            return {
                "success": False,
                "error": "Görselden metin okunamadı. Lütfen daha net bir fotoğraf çekin.",
                "rawText": "",
                "items": []
            }

        full_text = " ".join(results)
        raw_text = "\n".join(results)

        # Tutar bul
        amount = parse_amount_from_text(full_text)

        # Açıklama bul
        description = extract_description_from_text(results)

        # Kategori tahmin et
        category = clf.predict(full_text)

        items = []
        if amount:
            items.append({
                "amount": amount,
                "description": description,
                "predictedCategory": category,
                "finalCategory": category,
            })
        else:
            # Tutar bulunamadıysa 0 ile döndür, kullanıcı düzeltir
            items.append({
                "amount": 0.0,
                "description": description,
                "predictedCategory": category,
                "finalCategory": category,
            })

        return {
            "success": True,
            "rawText": raw_text,
            "items": items
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR hatası: {str(e)}")


# =========================
# GEMİNİ FİŞ ANALİZİ
# =========================

@app.post("/gemini-analyze")
async def gemini_analyze(file: UploadFile = File(...)):
    """
    Gemini Vision ile fiş/fatura analizi.
    - İşyeri adı, tarih, toplam tutar, ürün listesi, kategori döner.
    - GEMINI_API_KEY env değişkeni gereklidir.
    """
    if not gemini_service.is_available():
        raise HTTPException(
            status_code=503,
            detail="Gemini servisi kullanılamıyor. GEMINI_API_KEY tanımlı değil."
        )

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Dosya boş")

    result = gemini_service.analyze_receipt(contents)

    if not result.get("success"):
        raise HTTPException(
            status_code=422,
            detail=result.get("error", "Fiş analiz edilemedi")
        )

    # items boşsa total_amount'tan tek item oluştur
    items = result.get("items", [])
    if not items and result.get("total_amount"):
        items = [{
            "name": result.get("merchant_name") or "Harcama",
            "amount": result["total_amount"],
        }]

    return {
        "success": True,
        "merchant_name": result.get("merchant_name"),
        "date": result.get("date"),
        "total_amount": result.get("total_amount"),
        "items": items,
        "category": result.get("category", "Diğer"),
        "confidence": result.get("confidence", 0.8),
        "engine": "gemini-2.5-flash",
    }


@app.post("/smart-ocr")
async def smart_ocr(file: UploadFile = File(...)):
    """
    Akıllı fiş analizi:
    - Gemini API varsa → Gemini Vision (çok daha iyi)
    - Yoksa → EasyOCR + regex (eski yöntem, fallback)
    """
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Dosya boş")

    # --- Gemini yolu ---
    if gemini_service.is_available():
        result = gemini_service.analyze_receipt(contents)
        if result.get("success"):
            items = result.get("items", [])
            if not items and result.get("total_amount"):
                items = [{
                    "name": result.get("merchant_name") or "Harcama",
                    "amount": result["total_amount"],
                }]
            return {
                "success": True,
                "engine": "gemini",
                "merchant_name": result.get("merchant_name"),
                "date": result.get("date"),
                "total_amount": result.get("total_amount"),
                "items": items,
                "category": result.get("category", "Diğer"),
                "confidence": result.get("confidence", 0.8),
                "rawText": result.get("raw_response", ""),
            }
        # Gemini başarısız olduysa EasyOCR'a düş

    # --- EasyOCR fallback yolu ---
    try:
        reader = get_ocr_reader()
        image_np = normalize_image_bytes(contents)
        results = reader.readtext(image_np, detail=0, paragraph=False)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR hatası: {str(e)}")

    if not results:
        return {
            "success": False,
            "engine": "easyocr",
            "error": "Görselden metin okunamadı. Lütfen daha net bir fotoğraf çekin.",
            "items": [],
        }

    full_text = " ".join(results)
    raw_text = "\n".join(results)
    amount = parse_amount_from_text(full_text)
    description = extract_description_from_text(results)
    category = clf.predict(full_text)

    items = [{
        "name": description,
        "amount": amount or 0.0,
    }]

    return {
        "success": True,
        "engine": "easyocr",
        "merchant_name": description,
        "date": None,
        "total_amount": amount,
        "items": items,
        "category": category,
        "confidence": 0.5,
        "rawText": raw_text,
    }


# =========================
# AKILLI BÜTÇE TAHMİNİ
# Son 3 aya göre kategori bazlı bütçe önerisi
# =========================

class MonthlyCategoryStat(BaseModel):
    category: str
    month1: float  # 3 ay önce
    month2: float  # 2 ay önce
    month3: float  # geçen ay
    avg: float


class SmartBudgetItem(BaseModel):
    category: str
    avg3month: float
    recommended: float
    trend: str          # "artan" | "azalan" | "sabit"
    reason: str


class SmartBudgetResponse(BaseModel):
    items: List[SmartBudgetItem]
    total_recommended: float
    summary: str


@app.post("/smart-budget", response_model=SmartBudgetResponse)
def smart_budget(stats: List[MonthlyCategoryStat]):
    """3 aylık geçmişe göre Gemini destekli bütçe tahmini"""
    try:
        items = []
        total_rec = 0.0

        for s in stats:
            # Trend hesapla
            if s.month3 > s.month2 > s.month1:
                trend = "artan"
                rec = round(s.avg * 1.05)  # %5 pay bırak
            elif s.month3 < s.month2 < s.month1:
                trend = "azalan"
                rec = round(s.avg * 0.95)
            else:
                trend = "sabit"
                rec = round(s.avg)

            reason = f"Son 3 ay ort. {s.avg:.0f}₺, trend {trend}"
            items.append(SmartBudgetItem(
                category=s.category,
                avg3month=s.avg,
                recommended=float(rec),
                trend=trend,
                reason=reason
            ))
            total_rec += rec

        # Gemini varsa daha zengin yorum ekle
        if gemini_service.is_available() and items:
            try:
                cat_lines = "\n".join(
                    f"- {it.category}: ort {it.avg3month:.0f}₺, trend {it.trend}"
                    for it in items
                )
                prompt = (
                    f"Bir kullanıcının son 3 aylık harcama ortalamaları:\n{cat_lines}\n\n"
                    f"Toplam önerilen aylık bütçe: {total_rec:.0f}₺\n\n"
                    "Türkçe olarak 1-2 cümlelik genel bir bütçe özeti yaz. "
                    "Önemli kategorileri vurgula, tasarruf fırsatı varsa belirt."
                )
                summary = gemini_service.generate_text(prompt) or f"Aylık önerilen toplam bütçe: {total_rec:.0f}₺"
            except Exception:
                summary = f"Aylık önerilen toplam bütçe: {total_rec:.0f}₺"
        else:
            summary = f"Aylık önerilen toplam bütçe: {total_rec:.0f}₺"

        return SmartBudgetResponse(items=items, total_recommended=total_rec, summary=summary)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/gemini-status")
def gemini_status():
    """Gemini API'nin aktif olup olmadığını kontrol et"""
    return {
        "available": gemini_service.is_available(),
        "library_installed": gemini_service.GEMINI_AVAILABLE,
        "api_key_set": bool(__import__("os").getenv("GEMINI_API_KEY")),
    }


# =========================
# SERVER START
# =========================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

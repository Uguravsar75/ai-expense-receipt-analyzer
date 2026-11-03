"""
Gemini Vision ile Fiş/Fatura Analizi
- Fotoğraftan işyeri, tarih, ürünler, tutarlar, kategori çıkarır
- google-generativeai kütüphanesi gerekir
"""
import os
import json
import base64
import logging
import re
from typing import Optional

logger = logging.getLogger(__name__)

try:
    from google import genai
    from google.genai import types as genai_types
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-genai yüklü değil - Gemini devre dışı")


RECEIPT_PROMPT = """
Bu bir Türkçe fiş veya fatura fotoğrafıdır. Lütfen aşağıdaki bilgileri çıkar ve SADECE JSON formatında yanıt ver.

Çıkarman gereken bilgiler:
1. merchant_name: İşyeri/mağaza adı (string, bulunamazsa null)
2. date: Tarih (YYYY-MM-DD formatında, bulunamazsa null)
3. total_amount: Toplam tutar (sadece sayı, TL/₺ işareti olmadan, bulunamazsa null)
4. items: Tek tek ürün/hizmet listesi (her biri: name, amount)
5. category: Aşağıdakilerden biri seç:
   - "Market" (bakkal, süpermarket, manav)
   - "Yeme & İçme" (restoran, kafe, fast food)
   - "Ulaşım" (akaryakıt, otopark, taksi, otobüs)
   - "Faturalar" (elektrik, su, doğalgaz, internet, telefon)
   - "Sağlık" (eczane, hastane, doktor)
   - "Giyim" (kıyafet, ayakkabı, aksesuar)
   - "Eğlence" (sinema, oyun, müzik)
   - "Eğitim" (kitap, kurs, okul)
   - "Kira & Ev" (kira, ev eşyası, tadilat)
   - "Diğer"
6. confidence: Genel okuma güveni (0.0 - 1.0 arası)

SADECE geçerli JSON döndür, başka hiçbir şey yazma. Örnek format:
{
  "merchant_name": "Migros",
  "date": "2025-03-15",
  "total_amount": 245.50,
  "items": [
    {"name": "Ekmek", "amount": 12.50},
    {"name": "Süt 1L", "amount": 28.00}
  ],
  "category": "Market",
  "confidence": 0.92
}
"""


def is_available() -> bool:
    """Gemini API kullanılabilir mi?"""
    return GEMINI_AVAILABLE and bool(os.getenv("GEMINI_API_KEY"))


def _get_client():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY environment variable tanımlı değil")
    return genai.Client(api_key=api_key)


def generate_text(prompt: str) -> Optional[str]:
    """Serbest metin üret (özet, yorum vb.)"""
    try:
        client = _get_client()
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )
        return response.text.strip() if response.text else None
    except Exception as e:
        logger.warning("Gemini generate_text hatası: %s", e)
        return None


def analyze_receipt(image_bytes: bytes) -> dict:
    """
    Fiş/fatura görseli analiz et.

    Returns:
        {
            "success": bool,
            "merchant_name": str | None,
            "date": str | None,          # YYYY-MM-DD
            "total_amount": float | None,
            "items": [{"name": str, "amount": float}],
            "category": str,
            "confidence": float,
            "raw_response": str          # debug için
        }
    """
    if not GEMINI_AVAILABLE:
        return {"success": False, "error": "google-generativeai paketi yüklü değil"}

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {"success": False, "error": "GEMINI_API_KEY tanımlı değil"}

    try:
        client = _get_client()
        mime = _detect_mime_type(image_bytes)

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[
                RECEIPT_PROMPT,
                genai_types.Part.from_bytes(data=image_bytes, mime_type=mime),
            ],
        )
        raw_text = response.text.strip()

        parsed = _parse_json_response(raw_text)

        if parsed is None:
            logger.warning("Gemini JSON parse hatası. Ham yanıt: %s", raw_text[:300])
            return {
                "success": False,
                "error": "Yanıt ayrıştırılamadı",
                "raw_response": raw_text,
            }

        return {
            "success": True,
            "merchant_name": parsed.get("merchant_name"),
            "date": parsed.get("date"),
            "total_amount": _to_float(parsed.get("total_amount")),
            "items": _clean_items(parsed.get("items", [])),
            "category": parsed.get("category", "Diğer"),
            "confidence": float(parsed.get("confidence", 0.8)),
            "raw_response": raw_text,
        }

    except Exception as e:
        logger.error("Gemini analiz hatası: %s", e)
        return {"success": False, "error": str(e)}


def _detect_mime_type(data: bytes) -> str:
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return "image/jpeg"


def _parse_json_response(text: str) -> Optional[dict]:
    # Markdown kod bloğunu temizle
    text = re.sub(r"```(?:json)?", "", text).strip().rstrip("`").strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # JSON bloğunu bul
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group())
            except json.JSONDecodeError:
                pass
    return None


def _to_float(val) -> Optional[float]:
    if val is None:
        return None
    try:
        return float(str(val).replace(",", "."))
    except (ValueError, TypeError):
        return None


def _clean_items(items: list) -> list:
    clean = []
    for item in items:
        if not isinstance(item, dict):
            continue
        name = str(item.get("name", "")).strip()
        amount = _to_float(item.get("amount"))
        if name and amount is not None and amount > 0:
            clean.append({"name": name, "amount": amount})
    return clean

"""
Bütçe Danışmanlığı (Budget Advisory)
- Harcama düzenlerini analiz eder
- Uyarılar ve tasarruf önerileri sunar
"""
import logging
from typing import List, Dict

logger = logging.getLogger(__name__)


class BudgetAdvisor:
    """Harcama danışmanlığı sağlar"""

    # Referans değerler (Türkiye ortalaması)
    DAILY_SAFE_LIMIT = 500  # 500₺/gün
    DAILY_WARNING_LIMIT = 1000  # 1000₺/gün
    MONTHLY_SAFE_LIMIT = 15000  # 15000₺/ay

    # Kategori uyarı oranları (0-100 yüzde ölçeği)
    CATEGORY_WARNING_THRESHOLD = 40.0  # %40 üzeri uyarı
    CATEGORY_CRITICAL_THRESHOLD = 50.0  # %50 üzeri kritik

    @staticmethod
    def analyze(
        total_amount: float,
        average_daily: float,
        category_stats: List[Dict[str, float]]
    ) -> Dict:
        """
        Komprehensif harcama analizi

        Args:
            total_amount: Toplam harcama (₺)
            average_daily: Günlük ortalama (₺)
            category_stats: [{kategori, tutar, yüzde}, ...]

        Returns:
            {
                "advice": [str],  # Tavsiyeler
                "warnings": [str],  # Uyarılar
                "savings_potential": float,  # Tasarruf potansiyeli
                "risk_level": "low|medium|high"
            }
        """
        advice = []
        warnings = []
        risk_level = "low"
        savings_potential = 0.0

        # 1. Günlük Harcama Analizi
        if average_daily >= BudgetAdvisor.DAILY_WARNING_LIMIT:
            warnings.append(
                f"⚠️ UYARI: Günlük {average_daily:.0f}₺ harcıyorsun. "
                f"Aylık ~{average_daily * 30:.0f}₺ olabilir. "
                f"Bütçe hedefi belirle!"
            )
            risk_level = "high"
            savings_potential += average_daily * 0.15 * 30  # %15 tasarruf
        elif average_daily >= BudgetAdvisor.DAILY_SAFE_LIMIT:
            warnings.append(
                f"⚠️ ORTA UYARI: Günlük {average_daily:.0f}₺ ortalama. "
                f"Harcamalarını kontrol etmeyi düşün."
            )
            risk_level = "medium"
            savings_potential += average_daily * 0.10 * 30  # %10 tasarruf
        else:
            advice.append(
                f"✅ Günlük harcama kontrolün iyi ({average_daily:.0f}₺/gün)"
            )

        # 2. Toplam Harcama Analizi
        if total_amount > BudgetAdvisor.MONTHLY_SAFE_LIMIT:
            warnings.append(
                f"🔴 KRITIK: Ay başından itibaren {total_amount:.0f}₺ harcadın. "
                f"Aylık bütçenizi aşabilirsin!"
            )
        elif total_amount > BudgetAdvisor.MONTHLY_SAFE_LIMIT * 0.8:
            warnings.append(
                f"🟡 Toplam harcama {total_amount:.0f}₺ - "
                f"aylık limitine yaklaşıyorsun"
            )

        # 3. Kategori Analizi
        high_categories = [
            cat for cat in category_stats
            if cat.get("percentage", 0) >= BudgetAdvisor.CATEGORY_WARNING_THRESHOLD
        ]

        for cat in high_categories:
            pct = cat.get("percentage", 0)
            name = cat.get("category", "Bilinmeyen")

            if pct >= BudgetAdvisor.CATEGORY_CRITICAL_THRESHOLD:
                warnings.append(
                    f"🔴 {name} harcamaları çok yüksek ({pct:.0f}%). "
                    f"Detaylı gözden geçir!"
                )
                savings_potential += cat.get("amount", 0) * 0.10
            else:
                advice.append(
                    f"💡 {name} ({pct:.0f}%) - kontrol et"
                )

        # 4. Tasarruf Önerileri
        if savings_potential > 500:
            advice.append(
                f"💰 Tasarruf potansiyeli: ~{savings_potential:.0f}₺/ay"
            )

        # 5. Teşvik mesajı
        if risk_level == "low":
            advice.append("🎉 Harcama disiplinin çok iyi!")
        elif risk_level == "medium":
            advice.append("📊 Küçük ayarlamalarla daha iyi olabilir")

        return {
            "advice": advice,
            "warnings": warnings,
            "savings_potential": savings_potential,
            "risk_level": risk_level,
            "total_amount": total_amount,
            "average_daily": average_daily
        }

    @staticmethod
    def get_category_recommendation(category_name: str, percentage: float) -> str:
        """Kategori için tavsiye (percentage: 0-100 arası)"""
        benchmarks = {
            "Market": 25.0,
            "Yeme & İçme": 20.0,
            "Ulaşım": 15.0,
            "Eğitim": 10.0,
            "Giyim": 15.0,
            "Sağlık": 10.0,
            "Faturalar": 15.0,
            "Kira & Ev": 35.0,
            "Eğlence": 10.0,
            "Diğer": 10.0,
        }

        benchmark = benchmarks.get(category_name, 15.0)

        if percentage > benchmark * 1.5:
            return f"❌ {category_name} yüksek (Benchmark: {benchmark:.0f}%, Senin: {percentage:.0f}%)"
        elif percentage > benchmark:
            return f"🟡 {category_name} biraz yüksek"
        else:
            return f"✅ {category_name} kontrolde"

    @staticmethod
    def get_monthly_forecast(daily_average: float, days_passed: int, total_days: int = 30) -> Dict:
        """
        Ay sonu tahmini

        Args:
            daily_average: Günlük ortalama
            days_passed: Geçen gün sayısı
            total_days: Toplam gün (default 30)
        """
        remaining_days = total_days - days_passed
        current_total = daily_average * days_passed
        forecast = current_total + (daily_average * remaining_days)

        return {
            "current_total": current_total,
            "forecast_total": forecast,
            "remaining_days": remaining_days,
            "daily_average": daily_average,
            "message": f"Eğer bu hızla devam edersen aylık ~{forecast:.0f}₺ harcayacaksın"
        }

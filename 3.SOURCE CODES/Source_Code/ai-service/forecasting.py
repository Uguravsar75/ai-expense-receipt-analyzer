"""
Time-Series Forecasting (Tahminleme)
- Gelecek harcamaları tahmin eder
- ARIMA modeli kullanır
"""
import logging
from typing import List, Dict, Optional
import numpy as np
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# statsmodels import conditional - olmazsa graceful fallback
try:
    from statsmodels.tsa.arima.model import ARIMA
    STATSMODELS_AVAILABLE = True
except ImportError:
    STATSMODELS_AVAILABLE = False
    logger.warning("statsmodels yüklü değil - forecasting devre dışı")


class ExpenseForecast:
    """Harcama tahmini (Time-Series)"""
    
    @staticmethod
    def simple_forecast(
        daily_expenses: List[float],
        forecast_days: int = 7
    ) -> Dict:
        """
        Basit exponential smoothing tahmin
        (statsmodels olmadan)
        
        Args:
            daily_expenses: Son günlerin harcamaları
            forecast_days: Kaç gün ilerisini tahmin edecek
        """
        if len(daily_expenses) < 3:
            return {
                "error": "Tahmin için en az 3 günlük veri gerekli",
                "forecast": None
            }
        
        # Basit moving average
        recent_avg = np.mean(daily_expenses[-7:]) if len(daily_expenses) >= 7 else np.mean(daily_expenses)
        
        forecast = [recent_avg] * forecast_days
        confidence_interval = {
            "upper": [recent_avg * 1.3] * forecast_days,  # +30%
            "lower": [recent_avg * 0.7] * forecast_days,  # -30%
        }
        
        return {
            "forecast": forecast,
            "confidence_interval": confidence_interval,
            "predicted_daily_avg": recent_avg,
            "predicted_monthly": recent_avg * 30,
            "method": "Simple Moving Average"
        }

    @staticmethod
    def arima_forecast(
        daily_expenses: List[float],
        forecast_days: int = 7,
        order: tuple = (1, 1, 1)
    ) -> Dict:
        """
        ARIMA tabanlı tahmin
        (statsmodels gerekli)
        
        Args:
            daily_expenses: Son günlerin harcamaları
            forecast_days: Kaç gün ilerisini tahmin edecek
            order: (p, d, q) ARIMA parametreleri
        """
        if not STATSMODELS_AVAILABLE:
            logger.warning("statsmodels yüklü değil, basit tahmini kullan")
            return ExpenseForecast.simple_forecast(daily_expenses, forecast_days)
        
        if len(daily_expenses) < 5:
            logger.warning("ARIMA için yeterli veri yok")
            return ExpenseForecast.simple_forecast(daily_expenses, forecast_days)
        
        try:
            model = ARIMA(daily_expenses, order=order)
            fitted = model.fit()
            
            # Tahmin
            forecast_result = fitted.get_forecast(steps=forecast_days)
            forecast = forecast_result.predicted_mean.tolist()
            conf_int = forecast_result.conf_int(alpha=0.05)
            
            return {
                "forecast": forecast,
                "confidence_interval": {
                    "lower": conf_int.iloc[:, 0].tolist(),
                    "upper": conf_int.iloc[:, 1].tolist()
                },
                "predicted_daily_avg": np.mean(forecast),
                "predicted_monthly": np.mean(forecast) * 30,
                "method": f"ARIMA{order}",
                "accuracy_metrics": {
                    "aic": fitted.aic,
                    "bic": fitted.bic,
                }
            }
            
        except Exception as e:
            logger.error(f"ARIMA tahmin hatası: {e}")
            return ExpenseForecast.simple_forecast(daily_expenses, forecast_days)

    @staticmethod
    def predict_next_period(
        daily_expenses: List[float],
        period_days: int = 30
    ) -> Dict:
        """
        Gelecek dönem tahmini
        
        Args:
            daily_expenses: Son günlerin harcamaları
            period_days: Kaç gün
        """
        if len(daily_expenses) == 0:
            return {"error": "Veri bulunmuyor"}
        
        forecast = ExpenseForecast.arima_forecast(
            daily_expenses,
            forecast_days=period_days
        )
        
        if "error" in forecast:
            return forecast
        
        predicted_total = sum(forecast["forecast"])
        
        return {
            "period_days": period_days,
            "daily_forecast": forecast["forecast"],
            "predicted_daily_avg": forecast["predicted_daily_avg"],
            "predicted_total": predicted_total,
            "confidence": {
                "lower": sum(forecast["confidence_interval"]["lower"]),
                "upper": sum(forecast["confidence_interval"]["upper"])
            },
            "trend": ExpenseForecast._analyze_trend(daily_expenses),
            "method": forecast["method"]
        }

    @staticmethod
    def _analyze_trend(daily_expenses: List[float]) -> str:
        """Trendi belirle"""
        if len(daily_expenses) < 2:
            return "insufficient_data"
        
        recent = np.mean(daily_expenses[-7:]) if len(daily_expenses) >= 7 else np.mean(daily_expenses[-3:])
        older = np.mean(daily_expenses[:len(daily_expenses)//2])
        
        if recent > older * 1.2:
            return "📈 Artış eğilimi"
        elif recent < older * 0.8:
            return "📉 Azalış eğilimi"
        else:
            return "➡️ Stabil"

    @staticmethod
    def seasonal_decomposition(daily_expenses: List[float]) -> Dict:
        """
        Mevsimsel ayrıştırma (zaman izin verirse)
        
        Args:
            daily_expenses: Son günlerin harcamaları
        """
        if len(daily_expenses) < 14:
            return {"error": "Mevsimsel analiz için 14+ günlük veri gerekli"}
        
        try:
            from statsmodels.tsa.seasonal import seasonal_decompose
            
            result = seasonal_decompose(
                daily_expenses,
                model='additive',
                period=7  # Haftalık mevsimsellik
            )
            
            return {
                "trend": result.trend.tolist(),
                "seasonal": result.seasonal.tolist(),
                "residual": result.resid.tolist(),
                "has_seasonality": np.std(result.seasonal) > np.std(result.trend) * 0.2
            }
            
        except Exception as e:
            logger.warning(f"Mevsimsel ayrıştırma hatası: {e}")
            return {"error": str(e)}


# Standalone functions
def forecast_expenses(daily_expenses: List[float], days: int = 7) -> Dict:
    """Kolay kullanım"""
    return ExpenseForecast.arima_forecast(daily_expenses, days)


def predict_monthly(daily_expenses: List[float]) -> Dict:
    """Ay sonu tahmini"""
    return ExpenseForecast.predict_next_period(daily_expenses, 30)

"""
Anomali Tespiti (Outlier Detection)
- Anormal harcama düzenlerini tespit eder
- Örn: "Her gün 10₺ harcıyor ama birden 5000₺"
"""
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import logging

logger = logging.getLogger(__name__)


class AnomalyDetector:
    """Harcama anomalilerini tespit etmek için Isolation Forest kullanır"""
    
    def __init__(self, contamination=0.1):
        """
        Args:
            contamination: Anormal veri oranı (0-1)
        """
        self.model = IsolationForest(
            contamination=contamination,
            random_state=42,
            n_estimators=100
        )
        self.scaler = StandardScaler()
        self.is_fitted = False

    def fit(self, amounts):
        """
        Model eğitimi
        
        Args:
            amounts: Liste[float] - harcama tutarları
        """
        if len(amounts) < 5:
            logger.warning("Anomali tespiti için 5+ örnek gerekli")
            return False
        
        X = np.array(amounts).reshape(-1, 1)
        X_scaled = self.scaler.fit_transform(X)
        
        try:
            self.model.fit(X_scaled)
            self.is_fitted = True
            logger.info(f"Anomali modeli eğitildi: {len(amounts)} örnek")
            return True
        except Exception as e:
            logger.error(f"Anomali model eğitimi hatası: {e}")
            return False

    def predict(self, amounts):
        """
        Anomalileri tespit et
        
        Args:
            amounts: Liste[float] - harcama tutarları
            
        Returns:
            dict: {
                "anomalies": [index listesi],
                "normal": [index listesi],
                "scores": [anomali skorları]
            }
        """
        if not self.is_fitted or len(amounts) == 0:
            return {"anomalies": [], "normal": list(range(len(amounts))), "scores": []}
        
        try:
            X = np.array(amounts).reshape(-1, 1)
            X_scaled = self.scaler.transform(X)
            
            # Prediction: 1 = normal, -1 = anomali
            predictions = self.model.predict(X_scaled)
            scores = self.model.score_samples(X_scaled)
            
            anomaly_indices = [i for i, p in enumerate(predictions) if p == -1]
            normal_indices = [i for i, p in enumerate(predictions) if p == 1]
            
            logger.debug(f"Tespit: {len(anomaly_indices)} anomali, {len(normal_indices)} normal")
            
            return {
                "anomalies": anomaly_indices,
                "normal": normal_indices,
                "scores": scores.tolist(),
                "anomaly_amounts": [amounts[i] for i in anomaly_indices]
            }
            
        except Exception as e:
            logger.error(f"Anomali tespit hatası: {e}")
            return {"anomalies": [], "normal": list(range(len(amounts))), "scores": []}

    def get_anomaly_reason(self, amount, amounts_list):
        """
        Neden anomali olduğunu açıkla
        """
        mean = np.mean(amounts_list)
        std = np.std(amounts_list)
        
        if amount > mean + 3 * std:
            return f"Çok yüksek (Ortalama: {mean:.2f}₺, bu: {amount:.2f}₺)"
        elif amount < mean - 2 * std and amount > 0:
            return f"Çok düşük (Ortalama: {mean:.2f}₺, bu: {amount:.2f}₺)"
        else:
            return "Standart dış (istatistiksel)"


# Standalone function
def detect_anomalies(amounts, contamination=0.1):
    """Kolay kullanım için standalone fonksiyon"""
    detector = AnomalyDetector(contamination=contamination)
    detector.fit(amounts)
    return detector.predict(amounts)

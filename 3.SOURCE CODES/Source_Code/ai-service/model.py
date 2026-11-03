import joblib
import os
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression

class ExpenseClassifier:

    def __init__(self):
        self.vectorizer = TfidfVectorizer()
        self.model = LogisticRegression(max_iter=1000)
        # Singleton cache: pkl dosyaları ilk predict'te yüklenir
        self._vectorizer_cache = None
        self._model_cache = None

    def train(self, texts, labels):
        X = self.vectorizer.fit_transform(texts)
        self.model.fit(X, labels)

        joblib.dump(self.vectorizer, "vectorizer.pkl")
        joblib.dump(self.model, "model.pkl")

        # Cache'i güncelle
        self._vectorizer_cache = self.vectorizer
        self._model_cache = self.model

    def predict(self, text):
        # Cache'den yükle - her seferinde diskten okuma yok
        if self._vectorizer_cache is None or self._model_cache is None:
            if not os.path.exists("vectorizer.pkl") or not os.path.exists("model.pkl"):
                raise FileNotFoundError(
                    "Model dosyaları bulunamadı. Önce train.py çalıştırın."
                )
            self._vectorizer_cache = joblib.load("vectorizer.pkl")
            self._model_cache = joblib.load("model.pkl")

        X = self._vectorizer_cache.transform([text])
        return self._model_cache.predict(X)[0]

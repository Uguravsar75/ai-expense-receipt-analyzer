import 'package:flutter/material.dart';

/// AI Prediction Badge - Harcamaya AI tahmini göster
class AIPredictionBadge extends StatelessWidget {
  final String? predictedCategory;
  final bool showIcon;

  const AIPredictionBadge({
    super.key,
    required this.predictedCategory,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (predictedCategory == null || 
        predictedCategory!.isEmpty || 
        predictedCategory == "unknown" ||
        predictedCategory == "UNKNOWN") {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.smart_toy,
              size: 14,
              color: Colors.blue,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            "🤖 ${predictedCategory ?? 'Tahmin'}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Anomali Uyarısı
class AnomalyWarningBadge extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AnomalyWarningBadge({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Budget Tavsiyesi Card
class BudgetAdviceCard extends StatelessWidget {
  final List<String> adviceList;
  final List<String> warnings;
  final String riskLevel;
  final double savingsPotential;

  const BudgetAdviceCard({
    super.key,
    required this.adviceList,
    required this.warnings,
    required this.riskLevel,
    required this.savingsPotential,
  });

  Color get riskColor {
    switch (riskLevel) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
      default:
        return Colors.green;
    }
  }

  String get riskText {
    switch (riskLevel) {
      case "high":
        return "🔴 Yüksek Risk";
      case "medium":
        return "🟡 Orta Risk";
      case "low":
      default:
        return "🟢 Düşük Risk";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor.withValues(alpha: 0.15), riskColor.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Level Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      riskLevel == 'high' ? Icons.error : (riskLevel == 'medium' ? Icons.warning : Icons.check_circle),
                      color: riskColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      riskText.replaceAll('🔴 ', '').replaceAll('🟡 ', '').replaceAll('🟢 ', ''),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: riskColor.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (savingsPotential > 100)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "+${savingsPotential.toStringAsFixed(0)}₺",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            if (warnings.isNotEmpty || adviceList.isNotEmpty) const SizedBox(height: 16),
            
            // Warnings Section
            if (warnings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "DİKKAT",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "• $w",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Advice Section
            if (adviceList.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "YAPAY ZEKA ÖNERİLERİ",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...adviceList.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "• $a",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// AI Loading Widget
class AILoadingWidget extends StatelessWidget {
  final String message;

  const AILoadingWidget({
    super.key,
    this.message = "AI analiz yapılıyor...",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.smart_toy, size: 40, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Tahmin Değeri Display
class PredictionValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const PredictionValue({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyStatModel {
  final String date;   // yyyy-MM-dd
  final double total;

  DailyStatModel({
    required this.date,
    required this.total,
  });

  factory DailyStatModel.fromJson(Map<String, dynamic> json) {
    return DailyStatModel(
      date: json['date'],
      total: (json['total'] as num).toDouble(),
    );
  }

  // =========================
  // 📅 GÜN ETİKETİ (Pzt, Sal…)
  // =========================
  String get dayLabel {
    final d = DateTime.parse(date);
    const days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cts", "Paz"];
    return days[d.weekday - 1];
  }

  // =========================
  // 📆 KISA TARİH (01-03)
  // =========================
  String get shortDate {
    final d = DateTime.parse(date);
    return "${d.day.toString().padLeft(2, '0')}"
           "-${d.month.toString().padLeft(2, '0')}";
  }
}

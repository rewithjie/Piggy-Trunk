// Investment model

class Investment {
  final String id;
  final String hogRaiserId;
  final String raiserName;
  final double initialCapital;
  final String hogType;
  final int totalHog;
  final DateTime investmentDate;
  final String stage;

  Investment({
    required this.id,
    required this.hogRaiserId,
    required this.raiserName,
    required this.initialCapital,
    required this.hogType,
    required this.totalHog,
    required this.investmentDate,
    required this.stage,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    final rawCapital = json['initial_capital'];
    final rawTotalHog = json['total_hog'];

    return Investment(
      id: (json['id'] ?? '').toString(),
      hogRaiserId: (json['hog_raiser_id'] ?? '').toString(),
      raiserName: (json['raiser_name'] ?? '').toString(),
      initialCapital: rawCapital is num
          ? rawCapital.toDouble()
          : double.tryParse(rawCapital?.toString() ?? '0') ?? 0,
      hogType: (json['hog_type'] ?? '').toString(),
      totalHog: rawTotalHog is num
          ? rawTotalHog.toInt()
          : int.tryParse(rawTotalHog?.toString() ?? '0') ?? 0,
      investmentDate: json['investment_date'] != null
          ? DateTime.tryParse(json['investment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      stage: (json['stage'] ?? 'pending').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hog_raiser_id': hogRaiserId,
      'raiser_name': raiserName,
      'initial_capital': initialCapital,
      'hog_type': hogType,
      'total_hog': totalHog,
      'investment_date': investmentDate.toIso8601String(),
      'stage': stage,
    };
  }
}

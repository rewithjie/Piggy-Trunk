/// Dashboard Models without json_serializable (manual parsing)

class AdminUser {
  final String name;
  final String role;
  final String initials;

  AdminUser({
    required this.name,
    required this.role,
    required this.initials,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      name: json['name'] ?? 'Admin',
      role: json['role'] ?? 'Administrator',
      initials: json['initials'] ?? 'AD',
    );
  }
}

class LifecycleStage {
  final String label;
  final String duration;
  final String status;

  LifecycleStage({
    required this.label,
    required this.duration,
    required this.status,
  });

  factory LifecycleStage.fromJson(Map<String, dynamic> json) {
    return LifecycleStage(
      label: json['label'] ?? '',
      duration: json['duration'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class RaiserLifecycle {
  final String name;
  final String status;
  final List<LifecycleStage> categories;

  RaiserLifecycle({
    required this.name,
    required this.status,
    required this.categories,
  });

  factory RaiserLifecycle.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List?)
            ?.map((e) => LifecycleStage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return RaiserLifecycle(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      categories: categories,
    );
  }
}

class PigType {
  final int id;
  final String name;

  PigType({required this.id, required this.name});

  factory PigType.fromJson(Map<String, dynamic> json) {
    return PigType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Raiser {
  final int id;
  final String name;
  final String code;
  final String location;
  final String status;
  final PigType? pigType;

  Raiser({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.status,
    this.pigType,
  });

  factory Raiser.fromJson(Map<String, dynamic> json) {
    return Raiser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      pigType: json['pig_type'] != null
          ? PigType.fromJson(json['pig_type'] as Map<String, dynamic>)
          : null,
    );
  }
}

class InvestmentAllocation {
  final double fattening;
  final double sow;

  InvestmentAllocation({
    required this.fattening,
    required this.sow,
  });

  factory InvestmentAllocation.fromJson(Map<String, dynamic> json) {
    return InvestmentAllocation(
      fattening: (json['fattening'] as num?)?.toDouble() ?? 0.0,
      sow: (json['sow'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvestmentSummary {
  final int totalActive;
  final int batchCount;
  final InvestmentAllocation allocation;
  final double totalCapital;
  final double expectedProfit;

  InvestmentSummary({
    required this.totalActive,
    required this.batchCount,
    required this.allocation,
    required this.totalCapital,
    required this.expectedProfit,
  });

  factory InvestmentSummary.fromJson(Map<String, dynamic> json) {
    return InvestmentSummary(
      totalActive: json['totalActive'] ?? 0,
      batchCount: json['batchCount'] ?? 0,
      allocation: InvestmentAllocation.fromJson(
        (json['allocation'] as Map<String, dynamic>?) ?? {},
      ),
      totalCapital: (json['totalCapital'] as num?)?.toDouble() ?? 0.0,
      expectedProfit: (json['expectedProfit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardData {
  final List<Raiser> raisers;
  final Map<String, RaiserLifecycle> raiserLifecycles;
  final InvestmentSummary investmentSummary;
  final AdminUser user;

  DashboardData({
    required this.raisers,
    required this.raiserLifecycles,
    required this.investmentSummary,
    required this.user,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    print('Parsing dashboard data...');
    final raisersData = (json['raisers'] as List?)
            ?.map((e) => Raiser.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final lifecyclesData = json['raiserLifecycles'] as Map? ?? {};
    final raiserLifecycles = <String, RaiserLifecycle>{};
    lifecyclesData.forEach((key, value) {
      raiserLifecycles[key.toString()] =
          RaiserLifecycle.fromJson(value as Map<String, dynamic>);
    });

    return DashboardData(
      raisers: raisersData,
      raiserLifecycles: raiserLifecycles,
      investmentSummary: InvestmentSummary.fromJson(
        (json['investmentSummary'] as Map<String, dynamic>?) ?? {},
      ),
      user: AdminUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

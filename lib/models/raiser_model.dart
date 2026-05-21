import 'package:json_annotation/json_annotation.dart';

part 'raiser_model.g.dart';

@JsonSerializable()
class Raiser {
  final int id;
  final String name;
  final String code;
  final String location;
  final String status;
  @JsonKey(name: 'pig_type')
  final PigType? pigType;

  Raiser({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.status,
    this.pigType,
  });

  factory Raiser.fromJson(Map<String, dynamic> json) => _$RaiserFromJson(json);
  Map<String, dynamic> toJson() => _$RaiserToJson(this);
}

@JsonSerializable()
class PigType {
  final int id;
  final String name;

  PigType({required this.id, required this.name});

  factory PigType.fromJson(Map<String, dynamic> json) => _$PigTypeFromJson(json);
  Map<String, dynamic> toJson() => _$PigTypeToJson(this);
}

@JsonSerializable()
class LifecycleStage {
  final String label;
  final String duration;
  final String status;

  LifecycleStage({
    required this.label,
    required this.duration,
    required this.status,
  });

  factory LifecycleStage.fromJson(Map<String, dynamic> json) => _$LifecycleStageFromJson(json);
  Map<String, dynamic> toJson() => _$LifecycleStageToJson(this);
}

@JsonSerializable()
class RaiserLifecycle {
  final String name;
  final String status;
  final List<LifecycleStage> categories;

  RaiserLifecycle({
    required this.name,
    required this.status,
    required this.categories,
  });

  factory RaiserLifecycle.fromJson(Map<String, dynamic> json) => _$RaiserLifecycleFromJson(json);
  Map<String, dynamic> toJson() => _$RaiserLifecycleToJson(this);
}

@JsonSerializable()
class InvestmentAllocation {
  @JsonKey(name: 'fattening')
  final double fattening;
  final double sow;

  InvestmentAllocation({
    required this.fattening,
    required this.sow,
  });

  factory InvestmentAllocation.fromJson(Map<String, dynamic> json) => _$InvestmentAllocationFromJson(json);
  Map<String, dynamic> toJson() => _$InvestmentAllocationToJson(this);
}

@JsonSerializable()
class InvestmentSummary {
  @JsonKey(name: 'totalActive')
  final int totalActive;
  @JsonKey(name: 'batchCount')
  final int batchCount;
  final InvestmentAllocation allocation;
  @JsonKey(name: 'totalCapital')
  final double totalCapital;
  @JsonKey(name: 'expectedProfit')
  final double expectedProfit;

  InvestmentSummary({
    required this.totalActive,
    required this.batchCount,
    required this.allocation,
    required this.totalCapital,
    required this.expectedProfit,
  });

  factory InvestmentSummary.fromJson(Map<String, dynamic> json) => _$InvestmentSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$InvestmentSummaryToJson(this);
}

@JsonSerializable()
class DashboardData {
  final List<Raiser> raisers;
  @JsonKey(name: 'raiserLifecycles')
  final Map<String, RaiserLifecycle> raiserLifecycles;
  @JsonKey(name: 'investmentSummary')
  final InvestmentSummary investmentSummary;
  final AdminUser user;

  DashboardData({
    required this.raisers,
    required this.raiserLifecycles,
    required this.investmentSummary,
    required this.user,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => _$DashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardDataToJson(this);
}

@JsonSerializable()
class AdminUser {
  final String name;
  final String role;
  final String initials;

  AdminUser({
    required this.name,
    required this.role,
    required this.initials,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => _$AdminUserFromJson(json);
  Map<String, dynamic> toJson() => _$AdminUserToJson(this);
}

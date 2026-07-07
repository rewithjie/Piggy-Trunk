// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raiser_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Raiser _$RaiserFromJson(Map<String, dynamic> json) => Raiser(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String,
  location: json['location'] as String,
  status: json['status'] as String,
  pigType: json['pig_type'] == null
      ? null
      : PigType.fromJson(json['pig_type'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RaiserToJson(Raiser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'location': instance.location,
  'status': instance.status,
  'pig_type': instance.pigType,
};

PigType _$PigTypeFromJson(Map<String, dynamic> json) =>
    PigType(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$PigTypeToJson(PigType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

LifecycleStage _$LifecycleStageFromJson(Map<String, dynamic> json) =>
    LifecycleStage(
      label: json['label'] as String,
      duration: json['duration'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$LifecycleStageToJson(LifecycleStage instance) =>
    <String, dynamic>{
      'label': instance.label,
      'duration': instance.duration,
      'status': instance.status,
    };

RaiserLifecycle _$RaiserLifecycleFromJson(Map<String, dynamic> json) =>
    RaiserLifecycle(
      name: json['name'] as String,
      status: json['status'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => LifecycleStage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RaiserLifecycleToJson(RaiserLifecycle instance) =>
    <String, dynamic>{
      'name': instance.name,
      'status': instance.status,
      'categories': instance.categories,
    };

InvestmentAllocation _$InvestmentAllocationFromJson(
  Map<String, dynamic> json,
) => InvestmentAllocation(
  fattening: (json['fattening'] as num).toDouble(),
  sow: (json['sow'] as num).toDouble(),
);

Map<String, dynamic> _$InvestmentAllocationToJson(
  InvestmentAllocation instance,
) => <String, dynamic>{'fattening': instance.fattening, 'sow': instance.sow};

InvestmentSummary _$InvestmentSummaryFromJson(Map<String, dynamic> json) =>
    InvestmentSummary(
      totalActive: (json['totalActive'] as num).toInt(),
      batchCount: (json['batchCount'] as num).toInt(),
      allocation: InvestmentAllocation.fromJson(
        json['allocation'] as Map<String, dynamic>,
      ),
      totalCapital: (json['totalCapital'] as num).toDouble(),
      expectedProfit: (json['expectedProfit'] as num).toDouble(),
    );

Map<String, dynamic> _$InvestmentSummaryToJson(InvestmentSummary instance) =>
    <String, dynamic>{
      'totalActive': instance.totalActive,
      'batchCount': instance.batchCount,
      'allocation': instance.allocation,
      'totalCapital': instance.totalCapital,
      'expectedProfit': instance.expectedProfit,
    };

DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) =>
    DashboardData(
      raisers: (json['raisers'] as List<dynamic>)
          .map((e) => Raiser.fromJson(e as Map<String, dynamic>))
          .toList(),
      raiserLifecycles: (json['raiserLifecycles'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RaiserLifecycle.fromJson(e as Map<String, dynamic>)),
      ),
      investmentSummary: InvestmentSummary.fromJson(
        json['investmentSummary'] as Map<String, dynamic>,
      ),
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DashboardDataToJson(DashboardData instance) =>
    <String, dynamic>{
      'raisers': instance.raisers,
      'raiserLifecycles': instance.raiserLifecycles,
      'investmentSummary': instance.investmentSummary,
      'user': instance.user,
    };

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) => AdminUser(
  name: json['name'] as String,
  role: json['role'] as String,
  initials: json['initials'] as String,
);

Map<String, dynamic> _$AdminUserToJson(AdminUser instance) => <String, dynamic>{
  'name': instance.name,
  'role': instance.role,
  'initials': instance.initials,
};

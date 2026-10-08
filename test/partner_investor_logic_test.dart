import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Partner Investor Business Logic Tests', () {
    // 1. Currency Formatting
    test('Format currency with thousand separators and two decimals', () {
      String formatCurrency(double amount) {
        return amount.toStringAsFixed(2).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
      }

      expect(formatCurrency(0.0), '0.00');
      expect(formatCurrency(500), '500.00');
      expect(formatCurrency(1500.75), '1,500.75');
      expect(formatCurrency(25000), '25,000.00');
      expect(formatCurrency(1250000.5), '1,250,000.50');
    });

    // 2. Pig Type Classification
    test('Hog pig type classification correctly distinguishes Sow vs Fattening', () {
      String getHogPigType(Map<String, dynamic> hog, String fallbackType) {
        final raw = (hog['pig_type'] ?? hog['type_name'] ?? hog['type'] ?? '').toString().trim();
        if (raw.isNotEmpty && raw != 'null' && raw != 'N/A' && raw != 'None') {
          final l = raw.toLowerCase();
          return (l == 'sow' || l.contains('breed')) ? 'Sow' : 'Fattening';
        }
        final fallbackLower = fallbackType.toLowerCase();
        return (fallbackLower == 'sow' || fallbackLower.contains('breed')) ? 'Sow' : 'Fattening';
      }

      expect(getHogPigType({'pig_type': 'Fattening'}, 'Fattening'), 'Fattening');
      expect(getHogPigType({'pig_type': 'Sow'}, 'Fattening'), 'Sow');
      expect(getHogPigType({'pig_type': 'Breeding'}, 'Fattening'), 'Sow');
      expect(getHogPigType({'pig_type': 'sow/breeding'}, 'Fattening'), 'Sow');
      expect(getHogPigType({}, 'Sow'), 'Sow');
      expect(getHogPigType({}, 'Fattening'), 'Fattening');
    });

    // 3. Stage Sequences and Mapping
    test('Lifecycle stage lists and IDs for Fattening and Sow', () {
      const fatteningStages = [
        'Booster',
        'Pre-Starter',
        'Starter',
        'Grower',
        'Finisher',
        'Selling',
      ];
      const sowStages = [
        'Booster',
        'Pre-Starter',
        'Starter',
        'Grower',
        'Breeder',
        'Lactation',
      ];

      expect(fatteningStages.length, 6);
      expect(sowStages.length, 6);
      expect(fatteningStages.first, 'Booster');
      expect(fatteningStages.last, 'Selling');
      expect(sowStages.first, 'Booster');
      expect(sowStages.last, 'Lactation');

      String getStageFromId(int id, bool isSow) {
        final stages = isSow ? sowStages : fatteningStages;
        if (id >= 1 && id <= stages.length) {
          return stages[id - 1];
        }
        return 'Booster';
      }

      expect(getStageFromId(1, false), 'Booster');
      expect(getStageFromId(4, false), 'Grower');
      expect(getStageFromId(5, false), 'Finisher');
      expect(getStageFromId(6, false), 'Selling');

      expect(getStageFromId(1, true), 'Booster');
      expect(getStageFromId(5, true), 'Breeder');
      expect(getStageFromId(6, true), 'Lactation');
    });

    // 4. Feed & Nutritional Guidance Resolution
    test('Stage nutritional feed guidance matches development milestones', () {
      Map<String, String> getStageInfo(String stageName, bool isSow) {
        final s = stageName.trim().toLowerCase();
        if (isSow) {
          if (s.contains('boost')) {
            return {
              'duration': 'Day 1 - 30',
              'purpose': 'Early nutrition and immune defense development for replacement breeding prospects.',
              'feed': 'Booster Micro-pellets (20-22% CP)',
            };
          } else if (s.contains('breed')) {
            return {
              'duration': 'Day 151 - 210',
              'purpose': 'Active breeding cycle management, ovulation tracking, and gestation support.',
              'feed': 'Gestation & Breeder Mash',
            };
          } else if (s.contains('lactat')) {
            return {
              'duration': 'Day 211 - 270',
              'purpose': 'Post-farrowing maternal nourishment, high-yield milk production, and piglet weaning.',
              'feed': 'Lactation High-Energy Ration',
            };
          }
        } else {
          if (s.contains('boost')) {
            return {
              'duration': 'Day 1 - 30',
              'purpose': 'Post-weaning gut health preservation, rapid digestive tract enzyme development.',
              'feed': 'Booster Micro-pellets (20-22% CP)',
            };
          } else if (s.contains('finish')) {
            return {
              'duration': 'Day 121 - 150',
              'purpose': 'Target market weight accumulation (95-110 kg) and optimal carcass meat quality.',
              'feed': 'Finisher Feed (13-14% CP)',
            };
          } else if (s.contains('sell')) {
            return {
              'duration': 'Day 151+',
              'purpose': 'Final pre-market evaluation, commercial dispatch, and revenue liquidation.',
              'feed': 'Maintenance Ration / Market Prep',
            };
          }
        }
        return {'duration': '', 'purpose': '', 'feed': ''};
      }

      final fatBooster = getStageInfo('Booster', false);
      expect(fatBooster['feed']!.contains('20-22% CP'), isTrue);

      final fatFinisher = getStageInfo('Finisher', false);
      expect(fatFinisher['feed']!.contains('13-14% CP'), isTrue);

      final fatSelling = getStageInfo('Selling', false);
      expect(fatSelling['duration'], 'Day 151+');

      final sowBreeder = getStageInfo('Breeder', true);
      expect(sowBreeder['feed']!.contains('Breeder Mash'), isTrue);

      final sowLactation = getStageInfo('Lactation', true);
      expect(sowLactation['duration'], 'Day 211 - 270');
    });

    // 5. Notification Deduplication Key Logic
    test('Deduplication keys isolate unique reports and collapse duplicates', () {
      String buildNotificationDeduplicationKey(Map<String, dynamic> notif) {
        final meta = notif['metadata'];
        dynamic reportId;
        if (meta is Map) {
          reportId = meta['report_id'] ?? meta['reportId'];
        }
        if (reportId != null && reportId.toString().trim().isNotEmpty) {
          return 'rep_${reportId.toString().trim()}';
        }

        final cleanTitle = (notif['title']?.toString() ?? '').trim().toLowerCase();
        final cleanMsg = (notif['message']?.toString() ?? '').trim().toLowerCase();
        final rawTime = notif['created_at']?.toString() ?? '';
        final datePrefix = rawTime.length >= 10 ? rawTime.substring(0, 10) : '';
        return '${cleanTitle}___${cleanMsg}___$datePrefix';
      }

      final key1 = buildNotificationDeduplicationKey({
        'metadata': {'report_id': 42},
        'title': 'Health Alert',
      });
      final key2 = buildNotificationDeduplicationKey({
        'metadata': {'report_id': 42},
        'title': 'Different Title',
      });
      final key3 = buildNotificationDeduplicationKey({
        'title': 'Investment Confirmed',
        'message': 'You funded Batch 1',
        'created_at': '2026-10-09T03:00:00Z',
      });
      final key4 = buildNotificationDeduplicationKey({
        'title': 'Investment Confirmed',
        'message': 'You funded Batch 1',
        'created_at': '2026-10-09T03:05:00Z',
      });

      expect(key1, 'rep_42');
      expect(key2, 'rep_42');
      expect(key1 == key2, isTrue); // Collapsed by report_id!

      expect(key3 == key4, isTrue); // Collapsed on same date prefix!
    });

    // 6. Portfolio and Funded Hogs Calculation
    test('Calculate portfolio total and funded hogs correctly from active investments', () {
      final investments = [
        {'amount': 15000.0, 'status': 'active', 'total_hogs': 15},
        {'amount': 25000.0, 'status': 'approved', 'total_hogs': 20},
        {'amount': 10000.0, 'status': 'cancelled', 'total_hogs': 10},
        {'amount': 5000.0, 'status': 'pending', 'total_hogs': 5},
      ];

      double totalInvested = 0.0;
      int activeProjectsCount = 0;
      int totalHogsFunded = 0;

      for (var inv in investments) {
        final st = inv['status'].toString().toLowerCase();
        if (st == 'active' || st == 'approved') {
          totalInvested += (inv['amount'] as num).toDouble();
          activeProjectsCount++;
          totalHogsFunded += (inv['total_hogs'] as num).toInt();
        }
      }

      expect(totalInvested, 40000.0);
      expect(activeProjectsCount, 2);
      expect(totalHogsFunded, 35);
    });

    // 7. Hog Synthesis Fallback
    test('Synthesize hogs when database has active batch but hogs table rows are not yet populated', () {
      List<Map<String, dynamic>> synthesizeHogs(int count, String hogType, String stage) {
        final half = (count / 2).ceil();
        final list = <Map<String, dynamic>>[];
        final isSowBatch = hogType.toLowerCase().contains('sow');
        for (int i = 0; i < count; i++) {
          final isSow = (isSowBatch && i >= half) || isSowBatch;
          final sName = isSow ? 'Booster' : stage;
          list.add({
            'hog_id': i + 1,
            'tag_number': 'HOG-${i + 1}',
            'index': i + 1,
            'pig_type': isSow ? 'Sow' : 'Fattening',
            'stage': sName,
            'health_status': 'Healthy',
            'status': 'active',
          });
        }
        return list;
      }

      final hogs = synthesizeHogs(4, 'Fattening', 'Grower');
      expect(hogs.length, 4);
      expect(hogs[0]['tag_number'], 'HOG-1');
      expect(hogs[0]['pig_type'], 'Fattening');
      expect(hogs[0]['stage'], 'Grower');
      expect(hogs[0]['health_status'], 'Healthy');
      expect(hogs[3]['tag_number'], 'HOG-4');
    });
  });
}

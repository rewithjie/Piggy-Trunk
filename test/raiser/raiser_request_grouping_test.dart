import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hog Raiser Stock Request Grouping & Filtering Tests', () {
    List<Map<String, dynamic>> groupRequests(List<Map<String, dynamic>> list) {
      final Map<String, List<Map<String, dynamic>>> groupMap = {};
      for (final req in list) {
        final aKey = (req['assignment_id'] ?? '').toString();
        final notesKey = (req['notes'] ?? '').toString().trim();
        final statusKey = (req['status'] ?? 'pending').toString().toLowerCase();
        final createdAtStr = (req['created_at'] ?? req['request_date'] ?? '').toString();
        String timeKey = createdAtStr;
        try {
          final dt = DateTime.parse(createdAtStr);
          timeKey = '${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}';
        } catch (_) {
          timeKey = createdAtStr;
        }
        final key = [aKey, timeKey, notesKey, statusKey].join('__');
        groupMap.putIfAbsent(key, () => []).add(req);
      }

      final List<Map<String, dynamic>> result = [];
      for (final items in groupMap.values) {
        final primary = Map<String, dynamic>.from(items.first);
        primary['items'] = items;
        primary['is_group'] = items.length > 1;
        primary['item_count'] = items.length;
        final totalQty = items.fold<int>(0, (sum, i) {
          final q = i['quantity'];
          if (q is num) return sum + q.toInt();
          return sum + (int.tryParse(q?.toString() ?? '1') ?? 1);
        });
        primary['total_quantity'] = totalQty;
        result.add(primary);
      }
      return result;
    }

    test('Groups multi-item cart requests into a single grouped order', () {
      final rawRequests = [
        {
          'request_id': 101,
          'assignment_id': 5,
          'feed_type': 'Booster Feeds',
          'category': 'Feeds',
          'quantity': 3,
          'status': 'pending',
          'notes': 'Weekly restock',
          'created_at': '2026-10-05T08:30:00Z',
        },
        {
          'request_id': 102,
          'assignment_id': 5,
          'feed_type': 'Multivitamins 100ml',
          'category': 'Vitamins',
          'quantity': 2,
          'status': 'pending',
          'notes': 'Weekly restock',
          'created_at': '2026-10-05T08:30:15Z',
        },
      ];

      final grouped = groupRequests(rawRequests);
      expect(grouped.length, 1);
      expect(grouped.first['is_group'], true);
      expect(grouped.first['item_count'], 2);
      expect(grouped.first['total_quantity'], 5);
      expect(grouped.first['status'], 'pending');
    });

    test('Separates requests from different assignments or dates', () {
      final rawRequests = [
        {
          'request_id': 201,
          'assignment_id': 1,
          'feed_type': 'Starter Feeds',
          'quantity': 2,
          'status': 'pending',
          'created_at': '2026-10-01T10:00:00Z',
        },
        {
          'request_id': 202,
          'assignment_id': 2,
          'feed_type': 'Starter Feeds',
          'quantity': 4,
          'status': 'pending',
          'created_at': '2026-10-01T10:00:00Z',
        },
      ];

      final grouped = groupRequests(rawRequests);
      expect(grouped.length, 2);
    });

    test('Filters grouped requests by All, Pending, and Completed tabs', () {
      final requests = [
        {'request_id': 1, 'status': 'pending'},
        {'request_id': 2, 'status': 'for_approval'},
        {'request_id': 3, 'status': 'approved'},
        {'request_id': 4, 'status': 'rejected'},
        {'request_id': 5, 'status': 'distributed'},
      ];

      List<Map<String, dynamic>> filterByTab(String tab, List<Map<String, dynamic>> list) {
        if (tab == 'All') return list;
        if (tab == 'Pending') {
          return list.where((r) {
            final s = (r['status'] ?? '').toString().toLowerCase();
            return s == 'pending' || s == 'for_approval';
          }).toList();
        }
        return list.where((r) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          return s != 'pending' && s != 'for_approval';
        }).toList();
      }

      expect(filterByTab('All', requests).length, 5);
      expect(filterByTab('Pending', requests).length, 2);
      expect(filterByTab('Completed', requests).length, 3);
    });
  });
}

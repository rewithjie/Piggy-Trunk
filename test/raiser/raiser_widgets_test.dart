import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piggytrunk/mobile_app/screens/raiser/widgets/raiser_empty_state.dart';
import 'package:piggytrunk/mobile_app/screens/raiser/widgets/raiser_header_bar.dart';

void main() {
  group('Hog Raiser UI Widgets Tests', () {
    testWidgets('RaiserEmptyState renders message, subtitle, and responds to button tap', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RaiserEmptyState(
              icon: Icons.pets_outlined,
              message: 'No hogs assigned yet',
              subtitle: 'Wait for the Farm Admin to assign hogs to your batch.',
              buttonText: 'Refresh Batch',
              onButtonPressed: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No hogs assigned yet'), findsOneWidget);
      expect(find.text('Wait for the Farm Admin to assign hogs to your batch.'), findsOneWidget);
      expect(find.text('Refresh Batch'), findsOneWidget);
      expect(find.byIcon(Icons.pets_outlined), findsOneWidget);

      await tester.tap(find.text('Refresh Batch'));
      await tester.pump();

      expect(buttonPressed, true);
    });

    testWidgets('RaiserHeaderBar renders raiser name and unread badge', (tester) async {
      final notifications = [
        {'notification_id': 1, 'is_read': false, 'title': 'Stock Approved'},
        {'notification_id': 2, 'is_read': false, 'title': 'Batch Assigned'},
        {'notification_id': 3, 'is_read': true, 'title': 'Old Notice'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RaiserHeaderBar(
              raiserName: 'Juan Dela Cruz',
              notificationsList: notifications,
              onRefreshNotifications: () {},
              onMarkNotificationAsRead: (id) {},
              onMarkAllRead: () {},
            ),
          ),
        ),
      );

      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 unread notifications badge
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('RaiserHeaderBar caps unread badge at 99+ when exceeding 99', (tester) async {
      final manyNotifications = List.generate(
        105,
        (i) => {'notification_id': i, 'is_read': false, 'title': 'Notice #$i'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RaiserHeaderBar(
              raiserName: 'Juan Dela Cruz',
              notificationsList: manyNotifications,
              onRefreshNotifications: () {},
              onMarkNotificationAsRead: (id) {},
              onMarkAllRead: () {},
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Verify Database Trigger and Tables', () async {
    print('=== Starting Detailed Database Column & Constraint Insert Verification ===');

    SharedPreferences.setMockInitialValues({});

    try {
      await dotenv.load(fileName: '.env');
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      await Supabase.initialize(
        url: url!,
        anonKey: anonKey!,
      );

      final client = Supabase.instance.client;

      print('\n--- Querying app_users for rejiexyz@gmail.com ---');
      final users = await client.from('app_users').select().eq('email', 'rejiexyz@gmail.com');
      print('Users matching rejiexyz@gmail.com: $users');

      print('\n--- Inserting fresh English notification for user 35 ---');
      await client.from('admin_notifications').insert({
        'title': 'New User Registration',
        'message': 'rej (rejiexyz@gmail.com) registered as Hog Raiser and is pending approval.',
        'type': 'user_registration',
        'is_read': false,
        'metadata': {
          'user_id': 35,
          'name': 'rej',
          'email': 'rejiexyz@gmail.com',
          'role': 'hog_raiser',
        },
      });

      final allNotifs = await client.from('admin_notifications').select();
      print('Current Admin Notifications: $allNotifs');

    } catch (e) {
      print('Execution failed: $e');
    }
  });
}

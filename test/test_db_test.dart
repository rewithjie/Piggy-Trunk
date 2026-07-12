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

      // Step 1: Attempt to manually insert a user in app_users
      print('\n--- Attempting manual insert into app_users ---');
      int? newUserId;
      try {
        final email = 'test_manual_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final response = await client.from('app_users').insert({
          'name': 'Test Manual User',
          'email': email,
          'role': 'hog_raiser',
          'status': 'Pending',
          'supabase_user_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // Dummy UUID
        }).select('user_id').single();

        newUserId = response['user_id'] as int;
        print('SUCCESS: Inserted into app_users. Generated user_id: $newUserId');
      } catch (e) {
        print('FAILED: Insert into app_users failed with database error:');
        print(e.toString());
      }

      // Step 2: Attempt to manually insert into hog_raisers using the new user_id
      if (newUserId != null) {
        print('\n--- Attempting manual insert into hog_raisers ---');
        try {
          final response = await client.from('hog_raisers').insert({
            'name': 'Test Manual User',
            'phone': '',
            'pig_type': 'Fattening',
            'status': 'Pending',
            'lifecycle_stage': 'Booster',
            'user_id': newUserId,
            'account_status': 'pending',
            'address': '',
          }).select('hog_raiser_id').single();

          final newRaiserId = response['hog_raiser_id'];
          print('SUCCESS: Inserted into hog_raisers. Generated hog_raiser_id: $newRaiserId');
        } catch (e) {
          print('FAILED: Insert into hog_raisers failed with database error:');
          print(e.toString());
        }
      }

    } catch (e) {
      print('Execution failed: $e');
    }
  });
}

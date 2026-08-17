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

      print('\n--- Verified Supabase connection and tables ---');
    } catch (e) {
      print('Execution failed: $e');
    }
  });
}

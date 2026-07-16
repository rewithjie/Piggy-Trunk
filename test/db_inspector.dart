import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://ywwwrshblzyqmxkbkxsp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3d3dyc2hibHp5cW14a2JreHNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjU2MDMsImV4cCI6MjA5MzMwMTYwM30.ceKymQgbjU3IAbHxS2OUiOV9Mf5DxVxf9eBgzRuCHXo',
  );

  try {
    print('--- APP USERS ---');
    final users = await supabase.from('app_users').select();
    for (var u in users) {
      print('ID: ${u['user_id']}, Name: ${u['name']}, Email: ${u['email']}, Role: ${u['role']}, Status: ${u['status']}, SupabaseID: ${u['supabase_user_id']}');
    }

    print('\n--- HOG RAISERS ---');
    final raisers = await supabase.from('hog_raisers').select();
    for (var r in raisers) {
      print('ID: ${r['hog_raiser_id']}, Name: ${r['name']}, Email: ${r['email']}, UserID: ${r['user_id']}, AccountStatus: ${r['account_status']}, PigType: ${r['pig_type']}');
    }

    print('\n--- RECENT REQUESTS ---');
    final reqs = await supabase.from('stock_requests').select();
    print('Total requests: ${reqs.length}');

    print('\n--- ASSIGNMENTS ---');
    final assigns = await supabase.from('assignments').select();
    print('Total assignments: ${assigns.length}');
  } catch (e) {
    print('Error: $e');
  }
}

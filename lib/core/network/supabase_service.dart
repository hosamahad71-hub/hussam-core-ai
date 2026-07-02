import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance =
      SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://api.yemen-network.supabase.co',
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
    );
  }

  SupabaseClient get client =>
      Supabase.instance.client;
}

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return SupabaseClient(
        'https://tzssstsysaccrpidwhbo.supabase.co',
        'mock_anon_key_for_testing',
      );
    }
  }

  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://haven-sample-instance.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'demo_anon_key';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 15,
      ),
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Helper to get or subscribe to a realtime broadcast channel
  static RealtimeChannel getBroadcastChannel(String channelName) {
    return client.channel(channelName);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper for Supabase client.
/// Use this instead of calling Supabase.instance.client directly.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user. Null if not logged in.
  User? get currentUser => client.auth.currentUser;

  /// Current user ID. Throws if not logged in.
  String get currentUserId {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  /// Auth state stream — listen for sign in/out events.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;
}

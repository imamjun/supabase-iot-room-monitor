import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Mendapatkan status user saat ini
  User? get currentUser => _client.auth.currentUser;

  // Fungsi Login dengan Email & Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
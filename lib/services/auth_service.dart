import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

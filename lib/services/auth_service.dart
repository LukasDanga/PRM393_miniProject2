import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initialize();
  }

  void _initialize() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _fetchUser(session.user.id);
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _fetchUser(session.user.id);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUser(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    _currentUser = UserModel.fromJson(response);
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? email.split('@').first},
      );

      if (response.session == null) {
        _isLoading = false;
        notifyListeners();
        return 'Vui lòng kiểm tra email để xác nhận đăng ký.';
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is AuthException) return e.message;
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchUser(response.user!.id);
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is AuthException) return e.message;
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return 'Chưa đăng nhập';

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(updates)
            .eq('id', _currentUser!.id);
      }

      await _fetchUser(_currentUser!.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

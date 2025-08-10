import 'package:shared_preferences/shared_preferences.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/services/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String identifier, UserRole role) async {
    try {
      print('AuthService: Attempting login for $identifier with role $role');
      final user = await _databaseService.authenticate(identifier, role);
      if (user != null) {
        print('AuthService: User authenticated successfully: ${user.registrationNumber}');
        _currentUser = user;
        await _saveUserSession(user);
        print('AuthService: User session saved');
        return true;
      } else {
        print('AuthService: Authentication failed');
        return false;
      }
    } catch (e) {
      print('AuthService: Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearUserSession();
  }

  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_role', user.role.toString());
  }

  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }

  Future<void> loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        _currentUser = await _databaseService.getUserById(userId);
      }
    } catch (e) {
      print('Load user session error: $e');
    }
  }
}
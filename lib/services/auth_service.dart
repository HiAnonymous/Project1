import 'package:shared_preferences/shared_preferences.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/services/data_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DataService _dataService = DataService();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String identifier, UserRole role) async {
    final user = _dataService.authenticate(identifier, role);
    if (user != null) {
      _currentUser = user;
      await _saveUserSession(user);
      return true;
    }
    return false;
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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId != null) {
      _currentUser = _dataService.getUserById(userId);
    }
  }
}
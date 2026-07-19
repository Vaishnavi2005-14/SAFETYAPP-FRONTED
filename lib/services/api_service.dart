import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://safetyapp-backend-production.up.railway.app/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('contacts');
    await prefs.remove('profile_name');
    await prefs.remove('profile_age');
    await prefs.remove('profile_phone');
    await prefs.remove('profile_aadhaar');
    await prefs.remove('profile_custom_message');
    await prefs.remove('profile_shake_enabled');
    await prefs.remove('profile_shake_sensitivity');
  }

  static Future<bool> signup(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await saveToken(data['token']);
        await _cacheUserData(data['user']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveToken(data['token']);
        await _cacheUserData(data['user']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> forgotPassword(String email, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> googleLogin(String idToken) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'idToken': idToken}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveToken(data['token']);
        await _cacheUserData(data['user']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _cacheUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    if (user['contacts'] != null) {
      await prefs.setString('contacts', jsonEncode(user['contacts']));
    }

    if (user['profile'] != null) {
      final p = user['profile'];
      await prefs.setString('profile_name', p['name'] ?? '');
      await prefs.setString('profile_age', p['age'] ?? '');
      await prefs.setString('profile_phone', p['phone'] ?? '');
      await prefs.setString('profile_aadhaar', p['aadhaar'] ?? '');
      await prefs.setString('profile_custom_message', p['customMessage'] ?? '');
      await prefs.setBool('profile_shake_enabled', p['shakeEnabled'] ?? true);
      await prefs.setString(
          'profile_shake_sensitivity', p['shakeSensitivity'] ?? 'Medium');
    }
  }

  static Future<bool> syncWithServer() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _cacheUserData(data);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> saveProfile({
    required String name,
    required String age,
    required String phone,
    required String aadhaar,
    required String customMessage,
    required bool shakeEnabled,
    required String shakeSensitivity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_age', age);
    await prefs.setString('profile_phone', phone);
    await prefs.setString('profile_aadhaar', aadhaar);
    await prefs.setString('profile_custom_message', customMessage);
    await prefs.setBool('profile_shake_enabled', shakeEnabled);
    await prefs.setString('profile_shake_sensitivity', shakeSensitivity);

    final token = await getToken();
    if (token == null) return false;

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({
          'name': name,
          'age': age,
          'phone': phone,
          'aadhaar': aadhaar,
          'customMessage': customMessage,
          'shakeEnabled': shakeEnabled,
          'shakeSensitivity': shakeSensitivity,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', jsonEncode(contacts));

    final token = await getToken();
    if (token == null) return false;

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/user/contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'contacts': contacts}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

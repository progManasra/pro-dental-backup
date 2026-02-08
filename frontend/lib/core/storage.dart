import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kToken = "token";
  static const _kRole = "role";
  static const _kUserId = "userId";
  static const _kEmail = "email";
  static const _kName = "name";

  Future<void> saveSession({
    required String token,
    required String role,
    required int userId,
    required String email,
    required String name,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kRole, role);
    await p.setInt(_kUserId, userId);
    await p.setString(_kEmail, email);
    await p.setString(_kName, name);
  }

  Future<String?> token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  Future<String?> role() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  Future<int?> userId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kUserId);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kUserId);
    await p.remove(_kEmail);
    await p.remove(_kName);
  }
}

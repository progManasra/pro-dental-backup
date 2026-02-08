import 'package:get/get.dart';
import '../../core/api_client.dart';

class UsersController extends GetxController {
  final ApiClient api;
  UsersController(this.api);

  bool loading = false;
  String? error;
  List<dynamic> items = [];

  Future<void> loadUsers() async {
    loading = true;
    error = null;
    update();

    try {
      final data = await api.get("/users", auth: true);
      items = (data["items"] as List<dynamic>);
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      loading = false;
      update();
    }
  }

Future<void> createUser({
  required String fullName,
  required String email,
  required String role,
  required String password,
  String? specialization,
  String? dob,
}) async {
  final body = <String, dynamic>{
    "fullName": fullName,
    "email": email,
    "role": role,
    "password": password,
  };

  if (role == "DOCTOR") {
    final sp = (specialization ?? "").trim();
    if (sp.isNotEmpty) body["specialization"] = sp;
  }

  if (role == "PATIENT") {
    final d = (dob ?? "").trim();
    if (d.isNotEmpty) body["dob"] = d;
  }

  await api.post("/users", body, auth: true);
  await loadUsers();
}
 // ✅ update user
  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    await api.put("/users/$id", body, auth: true);
    await loadUsers();
  }

  // ✅ delete user
  Future<void> deleteUser(int id) async {
    await api.delete("/users/$id", auth: true);
    await loadUsers();
  }
}

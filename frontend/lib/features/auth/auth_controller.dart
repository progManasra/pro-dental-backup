import 'package:get/get.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';
import '../../app/routes.dart';

class AuthController extends GetxController {
  final ApiClient api;
  final Storage storage;

  AuthController(this.api, this.storage);

  bool loading = false;
  String? error;

  Future<void> login(String email, String password) async {
    loading = true;
    error = null;
    update();

    try {
      final data = await api.post("/auth/login", {"email": email, "password": password});
      final token = data["token"] as String;
      final user = data["user"] as Map<String, dynamic>;

      await storage.saveSession(
        token: token,
        role: user["role"],
        userId: user["id"],
        email: user["email"],
        name: user["fullName"],
      );

      final role = user["role"];
      if (role == "ADMIN") Get.offAllNamed(Routes.adminHome);
      if (role == "DOCTOR") Get.offAllNamed(Routes.doctorHome);
      if (role == "PATIENT") Get.offAllNamed(Routes.patientHome);

    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      loading = false;
      update();
    }
  }

  Future<void> logout() async {
    await storage.clear();
    Get.offAllNamed(Routes.login);
  }
}

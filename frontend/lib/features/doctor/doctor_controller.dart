import 'package:get/get.dart';
import '../../core/api_client.dart';

class DoctorController extends GetxController {
  final ApiClient api;
  DoctorController(this.api);

  bool loading = false;
  String? error;
  List<dynamic> items = [];

  Future<void> loadMyAppointments() async {
    loading = true;
    error = null;
    update();

    try {
      final data = await api.get("/appointments/me", auth: true);
      items = (data["items"] as List<dynamic>);
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      loading = false;
      update();
    }
  }
}

import 'package:get/get.dart';
import '../../core/api_client.dart';

class PatientController extends GetxController {
  final ApiClient api;
  PatientController(this.api);

  bool loading = false;
  String? error;

  List<dynamic> myAppointments = [];

  Future<void> loadMyAppointments() async {
    loading = true;
    error = null;
    update();

    try {
      final data = await api.get("/appointments/me", auth: true);
      myAppointments = (data["items"] as List<dynamic>);
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      loading = false;
      update();
    }
  }

  Future<void> book({
    required int doctorId,
    required String startAtIso,
    int durationMinutes = 30,
    String? reason,
  }) async {
    await api.post("/appointments/book", {
      "doctorId": doctorId,
      "startAt": startAtIso,
      "durationMinutes": durationMinutes,
      "reason": reason
    }, auth: true);
  }
}

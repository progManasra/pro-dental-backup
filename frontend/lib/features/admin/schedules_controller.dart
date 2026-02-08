import 'package:get/get.dart';
import '../../core/api_client.dart';

class SchedulesController extends GetxController {
  final ApiClient api;
  SchedulesController(this.api);

  Future<void> addWeeklyShift({
    required int doctorId,
    required int weekday,
    required String startTime,
    required String endTime,
    int slotMinutes = 30,
  }) async {
    await api.post("/schedules/weekly/$doctorId", {
      "weekday": weekday,
      "startTime": startTime,
      "endTime": endTime,
      "slotMinutes": slotMinutes
    }, auth: true);
  }

 Future<void> setOverride({
  required int doctorId,
  required String date,
  required bool isOff,
  String? startTime,
  String? endTime,
}) async {
  final body = <String, dynamic>{
    "date": date,
    "isOff": isOff,
  };

  // لا تبعت null أبداً
  if (!isOff) {
    body["startTime"] = startTime;
    body["endTime"] = endTime;
  }

  await api.post("/schedules/override/$doctorId", body, auth: true);
}

}

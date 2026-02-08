import 'package:get/get.dart';
import '../core/storage.dart';
import '../core/api_client.dart';

import '../features/auth/auth_controller.dart';
import '../features/admin/users_controller.dart';
import '../features/admin/schedules_controller.dart';
import '../features/doctor/doctor_controller.dart';
import '../features/patient/patient_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(Storage(), permanent: true);
    Get.put(ApiClient(Get.find<Storage>()), permanent: true);

    Get.put(AuthController(Get.find<ApiClient>(), Get.find<Storage>()), permanent: true);

    Get.put(UsersController(Get.find<ApiClient>()), permanent: true);
    Get.put(SchedulesController(Get.find<ApiClient>()), permanent: true);

    Get.put(DoctorController(Get.find<ApiClient>()), permanent: true);
    Get.put(PatientController(Get.find<ApiClient>()), permanent: true);
  }
}

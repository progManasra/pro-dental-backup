import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../../app/routes.dart';
import '../auth/auth_controller.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AppScaffold(
      title: "Doctor Dashboard",
      actions: [IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () => Get.toNamed(Routes.doctorAppointments),
            child: const Text("My Appointments"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../../app/routes.dart';
import '../auth/auth_controller.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AppScaffold(
      title: "Patient Dashboard",
      actions: [IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout))],
      child: Wrap(
        spacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => Get.toNamed(Routes.patientBook),
            child: const Text("Book Appointment"),
          ),
          ElevatedButton(
            onPressed: () => Get.toNamed(Routes.patientMyAppointments),
            child: const Text("My Appointments"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prodental_frontend/features/admin/doctor_schedule_board_page.dart';

import '../shared/widgets/app_scaffold.dart';
import '../auth/auth_controller.dart';

// ✅ استدعِ صفحات الأدمن مباشرة
import 'users_page.dart';
import 'schedules_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: "Admin Dashboard",
        actions: [
          IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Admin Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const TabBar(
              tabs: [
                Tab(text: "Manage Users"),
                Tab(text: "Manage Schedules"),
                Tab(text: "Board"), // 🆕

              ],
            ),

            const SizedBox(height: 12),

            // ✅ هذا أهم سطر: لازم Expanded
            Expanded(
              child: TabBarView(
                children: [
                  // ✅ نخلي كل صفحة هي اللي تهتم بالسكرول
                  UsersPage(),
                  SchedulesPage(),
                  DoctorScheduleBoardPage()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

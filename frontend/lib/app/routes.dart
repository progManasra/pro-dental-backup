import 'package:get/get.dart';
import '../features/auth/login_page.dart';
import '../features/admin/admin_dashboard_page.dart';
import '../features/admin/users_page.dart';
import '../features/admin/schedules_page.dart';
import '../features/doctor/doctor_dashboard_page.dart';
import '../features/doctor/doctor_appointments_page.dart';
import '../features/patient/patient_dashboard_page.dart';
import '../features/patient/book_appointment_page.dart';
import '../features/patient/my_appointments_page.dart';

class Routes {
  static const login = "/login";

  static const adminHome = "/admin";
  static const adminUsers = "/admin/users";
  static const adminSchedules = "/admin/schedules";

  static const doctorHome = "/doctor";
  static const doctorAppointments = "/doctor/appointments";

  static const patientHome = "/patient";
  static const patientBook = "/patient/book";
  static const patientMyAppointments = "/patient/appointments";
}

class AppRoutes {
  static final pages = <GetPage>[
    GetPage(name: Routes.login, page: () => const LoginPage()),

    GetPage(name: Routes.adminHome, page: () => const AdminDashboardPage()),
    GetPage(name: Routes.adminUsers, page: () => const UsersPage()),
    GetPage(name: Routes.adminSchedules, page: () => const SchedulesPage()),

    GetPage(name: Routes.doctorHome, page: () => const DoctorDashboardPage()),
    GetPage(name: Routes.doctorAppointments, page: () => const DoctorAppointmentsPage()),

    GetPage(name: Routes.patientHome, page: () => const PatientDashboardPage()),
    GetPage(name: Routes.patientBook, page: () => const BookAppointmentPage()),
    GetPage(name: Routes.patientMyAppointments, page: () => const MyAppointmentsPage()),
  ];
}

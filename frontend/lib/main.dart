import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'app/bindings.dart';

void main() {
  runApp(const ProDentalApp());
}

class ProDentalApp extends StatelessWidget {
  const ProDentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ProDental",
      theme: AppTheme.light(),
      initialBinding: AppBindings(),
      initialRoute: Routes.login,
      getPages: AppRoutes.pages,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/form_fields.dart';
import '../shared/widgets/loading.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (c) {
        return AppScaffold(
          title: "Login",
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: c.loading
                  ? const Loading(label: "Signing in...")
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextField(controller: email, label: "Email"),
                        const SizedBox(height: 12),
                        AppTextField(controller: password, label: "Password", obscure: true),
                        const SizedBox(height: 16),
                        if (c.error != null) ...[
                          Text(c.error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => c.login(email.text.trim(), password.text),
                            child: const Text("Login"),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Test users: admin@prodental.local / 1234 ..."),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

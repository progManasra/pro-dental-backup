import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/loading.dart';
import '../shared/widgets/form_fields.dart';
import 'users_controller.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  // Create form
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String role = "PATIENT";
  final specialization = TextEditingController();
  final dob = TextEditingController(); // YYYY-MM-DD (from datepicker)

  @override
  void initState() {
    super.initState();
    Get.find<UsersController>().loadUsers();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    specialization.dispose();
    dob.dispose();
    super.dispose();
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    dob.text = "$y-$m-$d";
    setState(() {});
  }

  Future<void> openEditUserDialog(Map<String, dynamic> u) async {
    final c = Get.find<UsersController>();

    final int id = int.parse(u["id"].toString());
    final fullNameCtrl = TextEditingController(text: (u["full_name"] ?? "").toString());
    final emailCtrl = TextEditingController(text: (u["email"] ?? "").toString());
    String editRole = (u["role"] ?? "PATIENT").toString();

    // optional fields
    final specCtrl = TextEditingController(text: "");
    final dobCtrl = TextEditingController(text: "");

    // new password optional
    final newPassCtrl = TextEditingController(text: "");

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit User #$id"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              AppTextField(controller: fullNameCtrl, label: "Full Name"),
              const SizedBox(height: 8),
              AppTextField(controller: emailCtrl, label: "Email"),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: editRole,
                items: const [
                  DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
                  DropdownMenuItem(value: "DOCTOR", child: Text("DOCTOR")),
                  DropdownMenuItem(value: "PATIENT", child: Text("PATIENT")),
                ],
                onChanged: (v) => setState(() => editRole = v ?? "PATIENT"),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Role"),
              ),

              const SizedBox(height: 8),
              AppTextField(controller: newPassCtrl, label: "New Password (optional)", obscure: true),

              const SizedBox(height: 8),
              if (editRole == "DOCTOR") ...[
                AppTextField(controller: specCtrl, label: "Specialization (optional)"),
              ],

              if (editRole == "PATIENT") ...[
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(DateTime.now().year - 20, 1, 1),
                      firstDate: DateTime(1900, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked == null) return;
                    final y = picked.year.toString().padLeft(4, '0');
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    dobCtrl.text = "$y-$m-$d";
                    // ignore: use_build_context_synchronously
                    (context as Element).markNeedsBuild();
                  },
                  child: IgnorePointer(
                    child: AppTextField(controller: dobCtrl, label: "DOB (tap to pick)"),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (ok != true) {
      fullNameCtrl.dispose();
      emailCtrl.dispose();
      specCtrl.dispose();
      dobCtrl.dispose();
      newPassCtrl.dispose();
      return;
    }

    try {
      final body = <String, dynamic>{
        "fullName": fullNameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "role": editRole,
      };

      final np = newPassCtrl.text.trim();
      if (np.isNotEmpty) body["password"] = np;

      if (editRole == "DOCTOR") {
        final sp = specCtrl.text.trim();
        if (sp.isNotEmpty) body["specialization"] = sp;
      }

      if (editRole == "PATIENT") {
        final d = dobCtrl.text.trim();
        if (d.isNotEmpty) body["dob"] = d;
      }

      await c.updateUser(id, body);
      Get.snackbar("OK", "User updated");
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    } finally {
      fullNameCtrl.dispose();
      emailCtrl.dispose();
      specCtrl.dispose();
      dobCtrl.dispose();
      newPassCtrl.dispose();
    }
  }

  Future<void> confirmDeleteUser(Map<String, dynamic> u) async {
    final c = Get.find<UsersController>();
    final int id = int.parse(u["id"].toString());
    final fullName = (u["full_name"] ?? "-").toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete user?"),
        content: Text("Are you sure you want to delete:\n$fullName (#$id)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await c.deleteUser(id);
      Get.snackbar("OK", "User deleted");
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UsersController>(
      builder: (c) {
        return AppScaffold(
          title: "Users",
          child: c.loading
              ? const Loading(label: "Loading users...")
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (_, box) {
                      final wide = box.maxWidth >= 900;

                      final createForm = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text("Create User", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            AppTextField(controller: name, label: "Full Name"),
                            const SizedBox(height: 8),
                            AppTextField(controller: email, label: "Email"),
                            const SizedBox(height: 8),
                            AppTextField(controller: password, label: "Password", obscure: true),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: role,
                              items: const [
                                DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
                                DropdownMenuItem(value: "DOCTOR", child: Text("DOCTOR")),
                                DropdownMenuItem(value: "PATIENT", child: Text("PATIENT")),
                              ],
                              onChanged: (v) => setState(() => role = v ?? "PATIENT"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Role",
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (role == "DOCTOR") ...[
                              AppTextField(controller: specialization, label: "Specialization (optional)"),
                              const SizedBox(height: 8),
                            ],
                            if (role == "PATIENT") ...[
                              InkWell(
                                onTap: pickDob,
                                child: IgnorePointer(
                                  child: AppTextField(controller: dob, label: "DOB (tap to pick)"),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await c.createUser(
                                    fullName: name.text.trim(),
                                    email: email.text.trim(),
                                    role: role,
                                    password: password.text,
                                    specialization: role == "DOCTOR" ? specialization.text.trim() : null,
                                    dob: role == "PATIENT" ? dob.text.trim() : null,
                                  );
                                  name.clear();
                                  email.clear();
                                  password.clear();
                                  specialization.clear();
                                  dob.clear();
                                  Get.snackbar("OK", "User created");
                                } catch (e) {
                                  Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
                                }
                              },
                              child: const Text("Create"),
                            ),
                          ],
                        ),
                      );

                      final usersList = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("Users List", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (c.error != null) ...[
                            Text(c.error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                          ],
                          Expanded(
                            child: ListView.separated(
                              itemCount: c.items.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (_, i) {
                                final u = (c.items[i] as Map).cast<String, dynamic>();
                                final id = (u["id"] ?? "-").toString();
                                final fullName = (u["full_name"] ?? "-").toString();
                                final em = (u["email"] ?? "-").toString();
                                final r = (u["role"] ?? "-").toString();

                                return ListTile(
                                  title: Text("$fullName  (#$id)"),
                                  subtitle: Text("$em • $r"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => openEditUserDialog(u),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => confirmDeleteUser(u),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );

                      if (wide) {
                        return Row(
                          children: [
                            Expanded(child: SingleChildScrollView(child: createForm)),
                            const SizedBox(width: 24),
                            Expanded(child: usersList),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          SingleChildScrollView(child: createForm),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Expanded(child: usersList),
                        ],
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

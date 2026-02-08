import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/api_client.dart';
import '../shared/widgets/app_scaffold.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  bool loading = false;
  String? error;
  List<dynamic> items = [];
  String status = "BOOKED";

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final api = Get.find<ApiClient>();
      final q = status == "ALL" ? "" : "?status=$status";
      final data = await api.get("/appointments/me$q", auth: true);
      items = (data["items"] as List?) ?? [];
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ✅ تنسيق تاريخ آمن
  String fmt(dynamic dt) {
    final s = (dt ?? "").toString();
    if (s.isEmpty) return "-";
    final v = s.replaceFirst("T", " ");
    return v.length >= 16 ? v.substring(0, 16) : v;
  }

  // ✅ تحويل ID بشكل آمن
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String safeStr(dynamic v, [String fallback = "-"]) {
    final s = (v ?? "").toString();
    return s.isEmpty ? fallback : s;
  }

  // ✅ رقم حجز مرئي
  String bookingNo(int? id) {
    if (id == null) return "-";
    return "PD-${id.toString().padLeft(6, '0')}";
  }

  Future<void> doctorAction({
    required int apptId,
    required String newStatus,
    String? currentNote,
  }) async {
    final noteCtrl = TextEditingController(text: (currentNote ?? "").toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newStatus == "COMPLETED" ? "Mark Completed" : "Mark No Show"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: "Doctor note (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            const Text(
              "ملاحظة: سيتم تحديث الحالة + ملاحظة الطبيب (إن وجدت).",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final api = Get.find<ApiClient>();

      // ✅ نفس مسار الحوار السابق:
      // POST /appointments/:id/doctor-action
      await api.post(
        "/appointments/$apptId/doctor-action",
        {
          "status": newStatus,
          // ارسل note فقط لو فيها قيمة
          if (noteCtrl.text.trim().isNotEmpty) "note": noteCtrl.text.trim(),
        },
        auth: true,
      );

      Get.snackbar("OK", "Updated");
      await load(silent: true);
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    } finally {
      noteCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Doctor Appointments",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: "BOOKED", child: Text("Booked")),
                    DropdownMenuItem(value: "COMPLETED", child: Text("Completed")),
                    DropdownMenuItem(value: "NO_SHOW", child: Text("No Show")),
                    DropdownMenuItem(value: "CANCELLED", child: Text("Cancelled")),
                    DropdownMenuItem(value: "ALL", child: Text("All")),
                  ],
                  onChanged: (v) {
                    setState(() => status = v ?? "BOOKED");
                    load();
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Status",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: load, child: const Text("Refresh")),
            ],
          ),
          const SizedBox(height: 12),

          if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            Expanded(
              child: Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else
            Expanded(
              // ✅ Pull-to-refresh يقلل موضوع "التحديث بياخد وقت"
              child: RefreshIndicator(
                onRefresh: () => load(silent: true),
                child: items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text("No appointments")),
                        ],
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final a = (items[i] as Map).cast<String, dynamic>();

                          final apptId = toInt(a["id"]);
                          final st = safeStr(a["status"], "");
                          final start = fmt(a["start_at"]);
                          final dur = toInt(a["duration_minutes"]) ?? 30;

                          final patient = safeStr(a["patient_name"]);
                          final note = safeStr(a["doctor_note"], "");
                          final updated = fmt(a["updated_at"]);

                          final canActions = (st == "BOOKED" && apptId != null);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${bookingNo(apptId)} • $start • $dur min",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Chip(label: Text(st.isEmpty ? "-" : st)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Text("Patient: $patient"),
                                  Text("Updated: $updated"),

                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text("Note: $note"),
                                  ],

                                  if (canActions) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.check_circle_outline),
                                            onPressed: () => doctorAction(
                                              apptId: apptId!,
                                              newStatus: "COMPLETED",
                                              currentNote: note,
                                            ),
                                            label: const Text("Complete"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.person_off_outlined),
                                            onPressed: () => doctorAction(
                                              apptId: apptId!,
                                              newStatus: "NO_SHOW",
                                              currentNote: note,
                                            ),
                                            label: const Text("No Show"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

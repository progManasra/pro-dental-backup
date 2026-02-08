import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../../core/api_client.dart';
import 'reschedule_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  bool loading = false;
  String? error;
  List<dynamic> items = [];
  String status = "ALL";

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = Get.find<ApiClient>();
      final q = (status == "ALL") ? "" : "?status=$status";
      final data = await api.get("/appointments/me$q", auth: true);
      items = (data["items"] as List?) ?? [];
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String fmt(dynamic dt) {
    final s = (dt ?? "").toString();
    if (s.isEmpty) return "-";
    final v = s.replaceFirst("T", " ");
    return v.length >= 16 ? v.substring(0, 16) : v;
  }

  String str(dynamic v, [String fallback = "-"]) {
    final s = (v ?? "").toString();
    return s.isEmpty ? fallback : s;
  }

  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> cancelAppt(int appointmentId) async {
    try {
      final api = Get.find<ApiClient>();
      await api.post("/appointments/$appointmentId/cancel", {}, auth: true);
      Get.snackbar("OK", "Cancelled");
      await load();
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> rescheduleAppt(int appointmentId, int doctorId) async {
    final changed = await Get.to(() => ReschedulePage(
          appointmentId: appointmentId,
          doctorId: doctorId,
        ));
    if (changed == true) await load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "My Appointments",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("All")),
                    DropdownMenuItem(value: "BOOKED", child: Text("Booked")),
                    DropdownMenuItem(value: "CANCELLED", child: Text("Cancelled")),
                    DropdownMenuItem(value: "COMPLETED", child: Text("Completed")),
                    DropdownMenuItem(value: "NO_SHOW", child: Text("No Show")),
                  ],
                  onChanged: (v) {
                    setState(() => status = v ?? "ALL");
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
              child: items.isEmpty
                  ? const Center(child: Text("No appointments found."))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final a = (items[i] as Map).cast<String, dynamic>();

                        final appointmentId = toInt(a["id"]);
                        final doctorId = toInt(a["doctor_id"]); // لازم يرجع من backend
                        final st = str(a["status"], "");

                        final start = fmt(a["start_at"]);
                        final dur = a["duration_minutes"] ?? 30;

                        final doctor = str(a["doctor_name"]);
                        final patient = str(a["patient_name"], "-");
                        final reason = str(a["reason"], "");
                        final apptId = toInt(a["id"]);
                        final bookingNo = apptId == null ? "-" : "PD-${apptId.toString().padLeft(6, '0')}";

                        final canActions = (st == "BOOKED") && appointmentId != null && doctorId != null;

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
                                        "$start  •  $dur min",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(label: Text(st.isEmpty ? "-" : st)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Booking #: $bookingNo"),
                                Text("Doctor: $doctor"),
                                Text("Patient: $patient"),
                                Text("Updated: ${fmt(a["updated_at"])}"),

                                if (reason.isNotEmpty) Text(reason),

                                if (st == "BOOKED") ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: canActions ? () => cancelAppt(appointmentId!) : null,
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: canActions
                                              ? () => rescheduleAppt(appointmentId!, doctorId!)
                                              : null,
                                          child: const Text("Reschedule"),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (!canActions)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text(
                                        "Backend did not return doctor_id/id. Fix API select fields.",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

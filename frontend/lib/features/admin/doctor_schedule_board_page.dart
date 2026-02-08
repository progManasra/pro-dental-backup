import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/api_client.dart';
import '../shared/widgets/app_scaffold.dart';

class DoctorScheduleBoardPage extends StatefulWidget {
  const DoctorScheduleBoardPage({super.key});

  @override
  State<DoctorScheduleBoardPage> createState() => _DoctorScheduleBoardPageState();
}

class _DoctorScheduleBoardPageState extends State<DoctorScheduleBoardPage> {
  bool loading = false;
  String? error;

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> doctors = [];
  List<String> times = [];

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$y-$m-$dd";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() => selectedDate = picked);
    await _loadBoard();
  }

  Future<void> _loadBoard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = Get.find<ApiClient>();
      final date = _ymd(selectedDate);

      final data = await api.get("/schedules/board?date=$date", auth: true);

      final rawDoctors = (data["doctors"] as List?) ?? [];
      doctors = rawDoctors.map((e) => (e as Map).cast<String, dynamic>()).toList();

      // collect union of times from all doctors slots
      final set = <String>{};
      for (final d in doctors) {
        final slots = (d["slots"] as List?) ?? [];
        for (final s in slots) {
          final m = (s as Map).cast<String, dynamic>();
          final t = (m["time"] ?? "").toString();
          if (t.isNotEmpty) set.add(t);
        }
      }
      final list = set.toList()..sort();
      times = list;
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> _findSlot(Map<String, dynamic> doctor, String time) {
    final slots = (doctor["slots"] as List?) ?? [];
    for (final s in slots) {
      final m = (s as Map).cast<String, dynamic>();
      if ((m["time"] ?? "").toString() == time) return m;
    }
    // لو مش موجود: يعني OFF / no shift window
    return {"time": time, "status": "OFF"};
  }

  Color _statusColor(String status) {
    switch (status) {
      case "AVAILABLE":
        return Colors.green.withOpacity(0.20);
      case "BOOKED":
        return Colors.red.withOpacity(0.20);
      case "CANCELLED":
        return Colors.orange.withOpacity(0.20);
      case "NO_SHOW":
        return Colors.purple.withOpacity(0.20);
      case "COMPLETED":
        return Colors.blue.withOpacity(0.20);
      default:
        return Colors.grey.withOpacity(0.15); // OFF
    }
  }

  Color _statusBorder(String status) {
    switch (status) {
      case "AVAILABLE":
        return Colors.green;
      case "BOOKED":
        return Colors.red;
      case "CANCELLED":
        return Colors.orange;
      case "NO_SHOW":
        return Colors.purple;
      case "COMPLETED":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case "AVAILABLE":
        return "AVAILABLE";
      case "BOOKED":
        return "BOOKED";
      case "CANCELLED":
        return "CANCELLED";
      case "NO_SHOW":
        return "NO SHOW";
      case "COMPLETED":
        return "COMPLETED";
      default:
        return "OFF";
    }
  }

  Future<void> _onSlotTap({
    required Map<String, dynamic> doctor,
    required Map<String, dynamic> slot,
  }) async {
    final status = (slot["status"] ?? "OFF").toString();
    final doctorName = (doctor["doctorName"] ?? doctor["doctor_name"] ?? "-").toString();
    final time = (slot["time"] ?? "-").toString();

    if (status == "OFF") {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No Shift"),
          content: Text("$doctorName is OFF at $time"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    if (status == "AVAILABLE") {
      // حاليا: عرض فقط، لاحقًا ممكن نعمل Admin booking
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Available Slot"),
          content: Text("$doctorName • $time"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        ),
      );
      return;
    }

    // BOOKED أو غيره: عرض تفاصيل + Actions
    final apptId = slot["appointmentId"];
    final patientName = (slot["patientName"] ?? "-").toString();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Appointment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Doctor: $doctorName"),
            Text("Time: $time"),
            Text("Status: ${_statusLabel(status)}"),
            const SizedBox(height: 8),
            Text("Patient: $patientName"),
            if (apptId != null) Text("Appointment ID: $apptId"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (apptId != null) ...[
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelAppointment(apptId);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _rescheduleAppointment(apptId, doctor, slot);
              },
              child: const Text("Reschedule"),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Cancel (يتطلب endpoint)
  // جرّب هذا أولاً:
  // POST /appointments/:id/cancel
  // إذا عندك مسار مختلف، عدله هنا.
  Future<void> _cancelAppointment(dynamic apptId) async {
    try {
      final api = Get.find<ApiClient>();
      await api.post("/appointments/$apptId/cancel", {}, auth: true);
      Get.snackbar("OK", "Cancelled");
      await _loadBoard();
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ✅ Reschedule (يتطلب endpoint)
  // جرّب:
  // POST /appointments/:id/reschedule  { startAt, durationMinutes, reason? }
  Future<void> _rescheduleAppointment(dynamic apptId, Map<String, dynamic> doctor, Map<String, dynamic> slot) async {
    final date = selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse((slot["time"] ?? "09:00").toString().split(":").first) ?? 9,
        minute: int.tryParse((slot["time"] ?? "09:00").toString().split(":").last) ?? 0,
      ),
    );
    if (pickedTime == null) return;

    final startAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ).toIso8601String();

    // إذا الباك يحسب duration من slotMinutes خليه ثابت هنا:
    // أو عدلها حسب بياناتك.
    final durationMinutes = 30;

    try {
      final api = Get.find<ApiClient>();
      await api.post(
        "/appointments/$apptId/reschedule",
        {
          "startAt": startAt,
          "durationMinutes": durationMinutes,
        },
        auth: true,
      );
      Get.snackbar("OK", "Rescheduled");
      await _loadBoard();
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Widget _doctorHeaderCell(String name) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _timeCell(String t) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _slotCell({
    required Map<String, dynamic> doctor,
    required Map<String, dynamic> slot,
  }) {
    final status = (slot["status"] ?? "OFF").toString();
    final patientName = (slot["patientName"] ?? "").toString();

    final color = _statusColor(status);
    final border = _statusBorder(status);

    return InkWell(
      onTap: () => _onSlotTap(doctor: doctor, slot: slot),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: border.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                status == "BOOKED" ? patientName : _statusLabel(status),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Doctor Schedule Board",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top controls
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_ymd(selectedDate)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loadBoard,
                  child: const Text("Refresh"),
                ),
                const Spacer(),
                if (doctors.isNotEmpty)
                  Text(
                    "Doctors: ${doctors.length} • Slots: ${times.length}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Expanded(child: Center(child: Text(error!, style: const TextStyle(color: Colors.red))))
            else if (doctors.isEmpty || times.isEmpty)
              const Expanded(child: Center(child: Text("No data for this day.")))
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header row: Time + Doctors horizontally scrollable
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 90, child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                            )),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: doctors.map((d) {
                                    final name = (d["doctorName"] ?? d["doctor_name"] ?? "-").toString();
                                    return _doctorHeaderCell(name);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body: vertical scroll, with horizontal scroll inside each row
                      Expanded(
                        child: ListView.separated(
                          itemCount: times.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, rowIndex) {
                            final t = times[rowIndex];

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _timeCell(t),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: doctors.map((d) {
                                        final slot = _findSlot(d, t);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                          child: _slotCell(doctor: d, slot: slot),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

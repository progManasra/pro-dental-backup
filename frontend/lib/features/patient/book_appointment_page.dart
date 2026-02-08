import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/widgets/app_scaffold.dart';
import '../../core/api_client.dart';
import 'patient_controller.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int? selectedDoctorId;
  List<dynamic> doctors = [];

  DateTime selectedDate = DateTime.now();
  bool loadingSlots = false;
  List<String> slots = [];

  final reason = TextEditingController(text: "Checkup");

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      final api = Get.find<ApiClient>();
      final data = await api.get("/users/by-role/DOCTOR", auth: true);
      doctors = data["items"];
      if (doctors.isNotEmpty) {
        selectedDoctorId = doctors.first["id"];
        await loadSlots();
      }
      setState(() {});
    } catch (e) {
      Get.snackbar("Error", "Failed to load doctors");
    }
  }

  String _dateToYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> loadSlots() async {
    if (selectedDoctorId == null) return;

    setState(() {
      loadingSlots = true;
      slots = [];
    });

    try {
      final api = Get.find<ApiClient>();
      final date = _dateToYmd(selectedDate);
      final data = await api.get("/appointments/available?doctorId=$selectedDoctorId&date=$date", auth: true);
      final list = (data["slots"] as List<dynamic>);
      setState(() {
        slots = list.map((e) => e.toString()).toList();
      });
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => loadingSlots = false);
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) {
      setState(() => selectedDate = d);
      await loadSlots();
    }
  }

  Future<void> bookSlot(String hhmm) async {
    final c = Get.find<PatientController>();
    final date = _dateToYmd(selectedDate);
    final iso = "${date}T$hhmm:00";

    try {
      await c.book(
        doctorId: selectedDoctorId!,
        startAtIso: iso,
        reason: reason.text.trim(),
      );
      Get.snackbar("OK", "Appointment booked at $hhmm");
      await loadSlots(); // refresh slots
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateToYmd(selectedDate);

    return AppScaffold(
      title: "Book Appointment",
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          children: [
            const Text("Choose doctor and date, then pick an available time slot.",
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: selectedDoctorId,
              items: doctors
                  .map((d) => DropdownMenuItem<int>(
                        value: d["id"],
                        child: Text(d["full_name"]),
                      ))
                  .toList(),
              onChanged: (v) async {
                setState(() => selectedDoctorId = v);
                await loadSlots();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Doctor",
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickDate,
                    child: Text("Date: $dateLabel"),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: loadingSlots ? null : loadSlots,
                  child: const Text("Refresh Slots"),
                ),
              ],
            ),

            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Reason (optional)",
              ),
            ),

            const SizedBox(height: 16),
            const Text("Available Slots", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (loadingSlots)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (selectedDoctorId == null)
              const Text("No doctors available.")
            else if (slots.isEmpty)
              const Text("No available times for this day. Try another date.")
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: slots.map((s) {
                  return SizedBox(
                    width: 110,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => bookSlot(s),
                      child: Text(s),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

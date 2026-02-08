import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/api_client.dart';
import '../shared/widgets/app_scaffold.dart';

class ReschedulePage extends StatefulWidget {
  final int appointmentId;
  final int doctorId;

  const ReschedulePage({super.key, required this.appointmentId, required this.doctorId});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  DateTime selectedDate = DateTime.now();
  bool loadingSlots = false;
  List<String> slots = [];
  final reason = TextEditingController();

  String _ymd(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    loadSlots();
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) {
      setState(() => selectedDate = d);
      await loadSlots();
    }
  }

  Future<void> loadSlots() async {
    setState(() {
      loadingSlots = true;
      slots = [];
    });

    try {
      final api = Get.find<ApiClient>();
      final date = _ymd(selectedDate);
      final data = await api.get(
        "/appointments/available?doctorId=${widget.doctorId}&date=$date",
        auth: true,
      );
      final list = (data["slots"] as List<dynamic>);
      setState(() => slots = list.map((e) => e.toString()).toList());
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => loadingSlots = false);
    }
  }

  Future<void> rescheduleTo(String hhmm) async {
    final api = Get.find<ApiClient>();
    final date = _ymd(selectedDate);
    final iso = "${date}T$hhmm:00";

    try {
      await api.post(
        "/appointments/${widget.appointmentId}/reschedule",
        {
          "startAt": iso,
          "durationMinutes": 30,
          if (reason.text.trim().isNotEmpty) "reason": reason.text.trim(),
        },
        auth: true,
      );
      Get.snackbar("OK", "Rescheduled to $hhmm");
      Get.back(result: true);
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _ymd(selectedDate);

    return AppScaffold(
      title: "Reschedule",
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          children: [
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
                  child: const Text("Refresh"),
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
                      onPressed: () => rescheduleTo(s),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/api_client.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  bool loading = false;
  String? error;
  List<dynamic> items = [];

  // ✅ قائمة الأطباء (نجيبها من users list اللي عندك أصلاً)
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    load();
    loadDoctors();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = Get.find<ApiClient>();
      final data = await api.get("/schedules/weekly", auth: true);
      items = (data["items"] as List?) ?? [];
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadDoctors() async {
    try {
      final api = Get.find<ApiClient>();
      // ✅ إذا عندك endpoint جاهز للأطباء استعمله
      // وإلا نخليها /users ونفلتر role=DOCTOR على الفرونت
      final data = await api.get("/users", auth: true);
      final all = (data["items"] as List?) ?? [];
      doctors = all
          .map((x) => (x as Map).cast<String, dynamic>())
          .where((u) => (u["role"]?.toString() ?? "") == "DOCTOR")
          .toList();
      setState(() {});
    } catch (_) {
      // مش مشكلة إذا ما توفر endpoint، بس وقتها رح نرجع لإدخال doctorId
    }
  }

  String dayName(int d) {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    if (d < 0 || d > 6) return d.toString();
    return days[d];
  }

  String hhmmFromTimeOfDay(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}";

  int? _asInt(dynamic v) => int.tryParse((v ?? "").toString());

  Future<void> openShiftDialog({Map<String, dynamic>? shift}) async {
    final isAdd = shift == null;

    int? doctorIdValue = isAdd ? (doctors.isNotEmpty ? _asInt(doctors.first["id"]) : null) : _asInt(shift["doctor_id"]);
    int weekdayValue = isAdd ? 1 : (_asInt(shift["weekday"]) ?? 1);

    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 13, minute: 0);

    // إذا تعديل: حاول تقرأ أول 5 أحرف HH:MM
    if (!isAdd) {
      final st = (shift["start_time"] ?? "09:00").toString();
      final et = (shift["end_time"] ?? "13:00").toString();
      final stH = int.tryParse(st.substring(0, 2)) ?? 9;
      final stM = int.tryParse(st.substring(3, 5)) ?? 0;
      final etH = int.tryParse(et.substring(0, 2)) ?? 13;
      final etM = int.tryParse(et.substring(3, 5)) ?? 0;
      start = TimeOfDay(hour: stH, minute: stM);
      end = TimeOfDay(hour: etH, minute: etM);
    }

    int slotMinutes = isAdd ? 30 : (_asInt(shift["slot_minutes"]) ?? 30);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isAdd ? "Add Weekly Shift" : "Edit Weekly Shift"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (isAdd) ...[
                  // ✅ اختيار Doctor من قائمة
                  if (doctors.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: doctorIdValue,
                      items: doctors
                          .map((d) => DropdownMenuItem<int>(
                                value: _asInt(d["id"]),
                                child: Text((d["full_name"] ?? d["fullName"] ?? "Doctor").toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setLocal(() => doctorIdValue = v),
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Doctor"),
                    )
                  else
                    const Text("⚠️ Doctors list not available. Check /users endpoint."),
                  const SizedBox(height: 10),
                ],

                DropdownButtonFormField<int>(
                  value: weekdayValue,
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(value: i, child: Text(dayName(i))),
                  ),
                  onChanged: (v) => setLocal(() => weekdayValue = v ?? 1),
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Weekday"),
                ),
                const SizedBox(height: 10),

                // ✅ وقت البداية
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Start"),
                  subtitle: Text(hhmmFromTimeOfDay(start)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: start);
                    if (picked != null) setLocal(() => start = picked);
                  },
                ),

                // ✅ وقت النهاية
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("End"),
                  subtitle: Text(hhmmFromTimeOfDay(end)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: end);
                    if (picked != null) setLocal(() => end = picked);
                  },
                ),

                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: slotMinutes,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text("15 min")),
                    DropdownMenuItem(value: 20, child: Text("20 min")),
                    DropdownMenuItem(value: 30, child: Text("30 min")),
                    DropdownMenuItem(value: 40, child: Text("40 min")),
                    DropdownMenuItem(value: 60, child: Text("60 min")),
                  ],
                  onChanged: (v) => setLocal(() => slotMinutes = v ?? 30),
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Slot Minutes"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save")),
          ],
        ),
      ),
    );

    if (ok != true) return;

    // ✅ منع التكرار قبل الإرسال (للإضافة فقط)
    if (isAdd && doctorIdValue != null) {
      final exists = items.any((x) {
        final m = (x as Map).cast<String, dynamic>();
        return _asInt(m["doctor_id"]) == doctorIdValue && _asInt(m["weekday"]) == weekdayValue;
      });

      if (exists) {
        Get.snackbar("Error", "This doctor already has a shift on ${dayName(weekdayValue)}");
        return;
      }
    }

    try {
      final api = Get.find<ApiClient>();

      final startTime = hhmmFromTimeOfDay(start);
      final endTime = hhmmFromTimeOfDay(end);

      if (isAdd) {
        if (doctorIdValue == null) {
          Get.snackbar("Error", "Doctor is required");
          return;
        }

        await api.post(
          "/schedules/weekly/$doctorIdValue",
          {
            "weekday": weekdayValue,
            "startTime": startTime,
            "endTime": endTime,
            "slotMinutes": slotMinutes,
          },
          auth: true,
        );
      } else {
        final id = shift["id"];
        await api.put(
          "/schedules/weekly/$id",
          {
            "weekday": weekdayValue,
            "startTime": startTime,
            "endTime": endTime,
            "slotMinutes": slotMinutes,
          },
          auth: true,
        );
      }

      await load();
      Get.snackbar("OK", "Saved");
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> deleteShift(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete shift?"),
        content: const Text("Are you sure you want to delete this weekly shift?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final api = Get.find<ApiClient>();
      // ✅ حسب اللي شغال عندك
      await api.post("/schedules/$id/delete", {}, auth: true);
      await load();
      Get.snackbar("OK", "Deleted");
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Weekly shifts by doctor",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => openShiftDialog(),
                  child: const Text("+ Add Shift"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: load, child: const Text("Refresh")),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (error != null)
                      ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                      : (items.isEmpty)
                          ? const Center(child: Text("No weekly shifts found."))
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final s = (items[i] as Map).cast<String, dynamic>();

                                final id = _asInt(s["id"]);
                                final doctorName = (s["doctor_name"] ?? "-").toString();
                                final weekday = _asInt(s["weekday"]) ?? 0;
                                final start = (s["start_time"] ?? "-").toString();
                                final end = (s["end_time"] ?? "-").toString();
                                final slot = (s["slot_minutes"] ?? 30).toString();

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    onTap: () => openShiftDialog(shift: s),
                                    title: Text("$doctorName • ${dayName(weekday)}"),
                                    subtitle: Text("${start.substring(0, 5)} - ${end.substring(0, 5)}  |  Slot: $slot min"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => openShiftDialog(shift: s),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: (id == null) ? null : () => deleteShift(id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

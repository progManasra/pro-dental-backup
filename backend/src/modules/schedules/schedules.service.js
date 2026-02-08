const { schedulesRepo } = require('./schedules.repo');
const { appointmentsRepo } = require('../appointments/appointments.repo');

function toMin(hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}
function toHHMM(mins) {
  const h = String(Math.floor(mins / 60)).padStart(2, '0');
  const m = String(mins % 60).padStart(2, '0');
  return `${h}:${m}`;
}

/* 🔥 الحل الحقيقي هنا */
function extractHHMM(v) {
  if (!v) return '';
  const s = v instanceof Date ? v.toISOString() : v.toString();

  if (s.includes('T') && s.length >= 16) return s.substring(11, 16);
  if (s.includes(' ') && s.length >= 16) return s.substring(11, 16);

  const d = new Date(s);
  if (!isNaN(d.getTime())) {
    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    return `${hh}:${mm}`;
  }
  return '';
}

const schedulesService = {

  addWeeklyShift(doctorId, dto) {
    return schedulesRepo.addWeeklyShift(doctorId, dto);
  },

  setOverride(doctorId, dto) {
    return schedulesRepo.upsertOverride(doctorId, dto);
  },

  async getDoctorSchedule(doctorId) {
    const weekly = await schedulesRepo.getWeekly(doctorId);
    const overrides = await schedulesRepo.getOverrides(doctorId);
    return { weekly, overrides };
  },

  async deleteWeekly(id) {
    return schedulesRepo.deleteWeekly(id);
  },

  async listWeekly() {
    return schedulesRepo.listWeekly();
  },

  async createWeekly(input) {
    return schedulesRepo.createWeekly(input);
  },

  async updateWeekly(id, input) {
    return schedulesRepo.updateWeekly(id, input);
  },

  // ================= DAILY BOARD =================

  async dailyBoard(dateYmd) {
    const doctors = await schedulesRepo.listDoctorsBasic();
    const appts = await appointmentsRepo.listForBoardByDate(dateYmd);

    const map = new Map();

    // 🔥 التصحيح هنا
    for (const a of appts) {
      const hhmm = extractHHMM(a.start_at);
      if (!hhmm) continue;
      map.set(`${a.doctor_id}|${hhmm}`, a);
    }

    console.log('[BOARD]', dateYmd, 'appts=', appts.length, 'map=', map.size);

    const rows = [];
    const weekday = new Date(dateYmd + 'T00:00:00').getDay();

    for (const d of doctors) {
      const doctorId = d.id;

      const ov = await schedulesRepo.getOverrideByDate(doctorId, dateYmd);
      if (ov && ov.is_off === 1) {
        rows.push({
          doctorId,
          doctorName: d.full_name,
          isOff: true,
          windows: [],
          slots: []
        });
        continue;
      }

      const weekly = await schedulesRepo.getWeeklyByWeekday(doctorId, weekday);
      if (!weekly || weekly.length === 0) {
        rows.push({
          doctorId,
          doctorName: d.full_name,
          isOff: false,
          windows: [],
          slots: []
        });
        continue;
      }

      const windows = weekly.map(w => ({
        start: (ov?.start_time ? ov.start_time : w.start_time).toString().substring(0, 5),
        end: (ov?.end_time ? ov.end_time : w.end_time).toString().substring(0, 5),
        slotMinutes: w.slot_minutes || 30
      }));

      const slots = [];

      for (const w of windows) {
        const s = toMin(w.start);
        const e = toMin(w.end);
        const step = w.slotMinutes;

        for (let t = s; t + step <= e; t += step) {
          const hhmm = toHHMM(t);
          const key = `${doctorId}|${hhmm}`;
          const a = map.get(key);

          if (!a) {
            slots.push({ time: hhmm, status: 'AVAILABLE' });
          } else {
            slots.push({
              time: hhmm,
              status: a.status,
              appointmentId: a.id,
              patientId: a.patient_id,
              patientName: a.patient_name || null
            });
          }
        }
      }

      rows.push({
        doctorId,
        doctorName: d.full_name,
        isOff: false,
        windows,
        slots
      });
    }

    return { date: dateYmd, doctors: rows };
  }
};

module.exports = { schedulesService };

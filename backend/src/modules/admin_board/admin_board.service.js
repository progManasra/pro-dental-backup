const { adminBoardRepo } = require('./admin_board.repo');

// helpers
function ymdToWeekday(dateYmd) {
  // dateYmd: "YYYY-MM-DD"
  const d = new Date(`${dateYmd}T00:00:00`);
  // JS: 0=Sun..6=Sat
  return d.getDay();
}

function hhmmFromDate(dt) {
  const d = new Date(dt);
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${hh}:${mm}`;
}

function addMinutesHHMM(hhmm, mins) {
  const [h, m] = hhmm.split(':').map(Number);
  const total = h * 60 + m + mins;
  const nh = Math.floor(total / 60);
  const nm = total % 60;
  return `${String(nh).padStart(2, '0')}:${String(nm).padStart(2, '0')}`;
}

function timeLess(a, b) {
  // "HH:MM"
  return a < b;
}

function buildSlots(startTime, endTime, slotMinutes) {
  const slots = [];
  let t = startTime;
  while (timeLess(t, endTime)) {
    slots.push(t);
    t = addMinutesHHMM(t, slotMinutes);
  }
  return slots;
}

function overlaps(slotTime, apptStartHHMM, apptEndHHMM) {
  // slotTime is start of slot
  return slotTime >= apptStartHHMM && slotTime < apptEndHHMM;
}

const adminBoardService = {
  async getBoard({ dateYmd, doctorId }) {
    const weekday = ymdToWeekday(dateYmd);

    const doctors = await adminBoardRepo.listDoctors(doctorId);
    const doctorIds = doctors.map((d) => d.id);

    const weekly = await adminBoardRepo.listWeeklyShiftsForWeekday(weekday, doctorIds);

    // overrides optional
    let overrides = [];
    try {
      overrides = await adminBoardRepo.listOverridesForDate(dateYmd, doctorIds);
    } catch (_) {
      overrides = [];
    }

    const appts = await adminBoardRepo.listAppointmentsForDate(dateYmd, doctorIds);

    // map helpers
    const weeklyByDoctor = new Map();
    for (const w of weekly) {
      weeklyByDoctor.set(w.doctor_id, w);
    }

    const overrideByDoctor = new Map();
    for (const o of overrides) {
      overrideByDoctor.set(o.doctor_id, o);
    }

    const apptsByDoctor = new Map();
    for (const a of appts) {
      if (!apptsByDoctor.has(a.doctor_id)) apptsByDoctor.set(a.doctor_id, []);
      apptsByDoctor.get(a.doctor_id).push(a);
    }

    let totalSlots = 0;
    let bookedSlots = 0;
    let doctorsWorking = 0;

    const boardDoctors = doctors.map((doc) => {
      const w = weeklyByDoctor.get(doc.id);
      if (!w) {
        return {
          id: doc.id,
          name: doc.full_name,
          working: false,
          reason: 'NO_SHIFT',
          slotMinutes: null,
          slots: []
        };
      }

      // apply override if exists
      const o = overrideByDoctor.get(doc.id);
      let startTime = String(w.start_time).substring(0, 5);
      let endTime = String(w.end_time).substring(0, 5);
      let slotMinutes = Number(w.slot_minutes || 30);

      if (o) {
        if (o.is_off) {
          return {
            id: doc.id,
            name: doc.full_name,
            working: false,
            reason: 'OFF_OVERRIDE',
            slotMinutes,
            slots: []
          };
        }
        if (o.start_time) startTime = String(o.start_time).substring(0, 5);
        if (o.end_time) endTime = String(o.end_time).substring(0, 5);
      }

      const slotTimes = buildSlots(startTime, endTime, slotMinutes);
      doctorsWorking += 1;
      totalSlots += slotTimes.length;

      const myAppts = apptsByDoctor.get(doc.id) || [];

      // prepare appointment intervals (HH:MM..HH:MM)
      const intervals = myAppts.map((a) => {
        const st = hhmmFromDate(a.start_at);
        const end = addMinutesHHMM(st, Number(a.duration_minutes || 30));
        return {
          id: a.id,
          status: a.status,
          patientName: a.patient_name,
          patientId: a.patient_id,
          startHHMM: st,
          endHHMM: end,
          reason: a.reason || null
        };
      });

      const slots = slotTimes.map((t) => {
        // default FREE
        let slot = {
          time: t,
          status: 'FREE',
          color: 'GREEN'
        };

        // find any appointment covering this slot
        for (const it of intervals) {
          if (overlaps(t, it.startHHMM, it.endHHMM)) {
            // display booked blocks as busy
            slot = {
              time: t,
              status: it.status || 'BOOKED',
              color:
                it.status === 'BOOKED' ? 'RED'
                : it.status === 'CANCELLED' ? 'GRAY'
                : it.status === 'COMPLETED' ? 'BLUE'
                : it.status === 'NO_SHOW' ? 'ORANGE'
                : 'RED',
              appointmentId: it.id,
              patientName: it.patientName,
              patientId: it.patientId,
              reason: it.reason
            };
            break;
          }
        }

        if (slot.status === 'BOOKED') bookedSlots += 1;
        return slot;
      });

      const availableSlots = slots.filter((s) => s.status === 'FREE').length;

      return {
        id: doc.id,
        name: doc.full_name,
        working: true,
        startTime,
        endTime,
        slotMinutes,
        totals: {
          total: slots.length,
          booked: slots.filter((s) => s.status === 'BOOKED').length,
          available: availableSlots
        },
        slots
      };
    });

    const availableSlots = totalSlots - bookedSlots;
    const utilization = totalSlots === 0 ? 0 : Math.round((bookedSlots / totalSlots) * 100);

    return {
      ok: true,
      date: dateYmd,
      weekday,
      stats: {
        doctorsWorking,
        totalSlots,
        bookedSlots,
        availableSlots,
        utilizationPercent: utilization
      },
      doctors: boardDoctors
    };
  },

  async getAppointmentDetails(id) {
    const a = await adminBoardRepo.getAppointmentDetails(id);
    if (!a) throw new Error('Appointment not found');
    return a;
  },

  async cancelAppointment(id) {
    const ok = await adminBoardRepo.adminCancelAppointment(id);
    if (!ok) throw new Error('Cannot cancel this appointment');
    return true;
  },

  async rescheduleAppointment(id, payload) {
    // payload: {startAt, durationMinutes, reason}
    const a = await adminBoardRepo.getAppointmentDetails(id);
    if (!a) throw new Error('Appointment not found');

    const durationMinutes = Number(payload.durationMinutes || a.duration_minutes || 30);
    const startAt = payload.startAt;
    if (!startAt) throw new Error('startAt is required');

    // (اختياري) فحص overlap لو عندك hasOverlapExcluding في appointments.repo
    // لو تحب نربطه نضيفه، لكن الآن نخليه بسيط حتى لا نكسر شيء.

    const out = await adminBoardRepo.adminRescheduleAppointment(
      id,
      startAt,
      durationMinutes,
      payload.reason ?? a.reason
    );

    return out;
  }
};

module.exports = { adminBoardService };

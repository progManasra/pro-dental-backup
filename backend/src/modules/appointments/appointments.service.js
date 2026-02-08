const { schedulesRepo } = require('../schedules/schedules.repo');
const { appointmentsRepo } = require('./appointments.repo');

function toYMD(dateObj) {
  const y = dateObj.getFullYear();
  const m = String(dateObj.getMonth() + 1).padStart(2, '0');
  const d = String(dateObj.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

// Sunday=0..Saturday=6 (JS getDay نفس الشي)
const appointmentsService = {
  async myAppointments(user) {
    if (user.role === 'DOCTOR') return appointmentsRepo.listByDoctor(user.id);
    if (user.role === 'PATIENT') return appointmentsRepo.listByPatient(user.id);
    return [];
  },

  async book(user, { doctorId, startAt, durationMinutes, reason }) {
    const patientId = user.id;
    const startDate = new Date(startAt);
    if (Number.isNaN(startDate.getTime())) {
      const err = new Error('Invalid startAt');
      err.status = 400;
      throw err;
    }

    // 1) تحقق من التوفر (Override أولاً، ثم Weekly)
    const dateYmd = toYMD(startDate);
    const weekday = startDate.getDay();

    const override = await schedulesRepo.getOverrideByDate(doctorId, dateYmd);
    if (override && override.is_off === 1) {
      const err = new Error('Doctor is off on this date');
      err.status = 409;
      throw err;
    }

    let windows = [];
    if (override && override.start_time && override.end_time) {
      windows = [{ start: override.start_time, end: override.end_time }];
    } else {
      const weekly = await schedulesRepo.getWeeklyByWeekday(doctorId, weekday);
      windows = weekly.map((w) => ({ start: w.start_time, end: w.end_time }));
    }

    if (windows.length === 0) {
      const err = new Error('Doctor not available on this day');
      err.status = 409;
      throw err;
    }

    // 2) تحقق أن startAt يقع ضمن نافذة دوام واحدة
    const hhmm = startDate.toTimeString().slice(0, 5); // "HH:MM"
    const within = windows.some((w) => hhmm >= w.start.slice(0, 5) && hhmm < w.end.slice(0, 5));
    if (!within) {
      const err = new Error('Requested time outside working hours');
      err.status = 409;
      throw err;
    }

    // 3) تحقق من عدم التعارض مع مواعيد الطبيب
    const conflict = await appointmentsRepo.hasOverlap(doctorId, startDate, durationMinutes);
    if (conflict) {
      const err = new Error('Time slot already booked');
      err.status = 409;
      throw err;
    }

    // 4) إنشاء الموعد
    return appointmentsRepo.create({
      doctorId,
      patientId,
      startAt: startDate,
      durationMinutes,
      reason: reason || null
    });
  },
async availableSlots({ doctorId, date }) {
  // date: "YYYY-MM-DD"
  const weekday = new Date(date + "T00:00:00").getDay(); // 0..6

  // 1) Override (الأولوية)
  const override = await schedulesRepo.getOverrideByDate(doctorId, date);
  if (override && override.is_off === 1) {
    return { date, doctorId, slots: [], start: null, end: null, slotMinutes: null };
  }

  // 2) Weekly windows
  let windows = [];
  let slotMinutes = 30;

  if (override && override.start_time && override.end_time) {
    windows = [{ start: override.start_time.slice(0, 5), end: override.end_time.slice(0, 5) }];
    // لو عندك slot_minutes في override (مش ضروري) استخدمه
    if (override.slot_minutes) slotMinutes = Number(override.slot_minutes) || 30;
  } else {
    const weekly = await schedulesRepo.getWeeklyByWeekday(doctorId, weekday);
    // weekly ممكن يرجع عدة نوافذ
    windows = (weekly || []).map((w) => ({
      start: String(w.start_time).slice(0, 5),
      end: String(w.end_time).slice(0, 5)
    }));

    // لو عندك slot_minutes على مستوى الشفت الأسبوعي
    if (weekly && weekly.length > 0 && weekly[0].slot_minutes) {
      slotMinutes = Number(weekly[0].slot_minutes) || 30;
    }
  }

  if (windows.length === 0) {
    return { date, doctorId, slots: [], start: null, end: null, slotMinutes };
  }

  // 3) get taken HH:MM
  const taken = await appointmentsRepo.listTakenSlots(doctorId, date);
  // توقعنا: listTakenSlots ترجع Set أو Array. خلّينا نغطي الحالتين
  const takenSet = (taken instanceof Set) ? taken : new Set((taken || []).map(String));

  const toMin = (hhmm) => {
    const [h, m] = hhmm.split(':').map(Number);
    return h * 60 + m;
  };
  const toHHMM = (mins) => {
    const h = String(Math.floor(mins / 60)).padStart(2, '0');
    const m = String(mins % 60).padStart(2, '0');
    return `${h}:${m}`;
  };

  // 4) build slots من كل نافذة
  const slots = [];
  for (const w of windows) {
    const s = toMin(w.start);
    const e = toMin(w.end);
    for (let t = s; t + slotMinutes <= e; t += slotMinutes) {
      const hhmm = toHHMM(t);
      if (!takenSet.has(hhmm)) slots.push(hhmm);
    }
  }

  // للتسهيل في UI: رجّع أول نافذة كـ start/end
  return {
    date,
    doctorId,
    slots,
    start: windows[0].start,
    end: windows[0].end,
    slotMinutes
  };
},

async cancel(user, apptId) {
  return appointmentsRepo.cancelByPatient(user.id, apptId);
},

async reschedule(user, apptId, { startAt, durationMinutes, reason }) {
  const patientId = user.id;

  // 0) تأكد الموعد تابع للمريض وحالته BOOKED
  const appt = await appointmentsRepo.findById(apptId);
  if (!appt || appt.patient_id !== patientId) {
    const err = new Error('Appointment not found');
    err.status = 404;
    throw err;
  }
  if (appt.status !== 'BOOKED') {
    const err = new Error('Only BOOKED appointments can be rescheduled');
    err.status = 409;
    throw err;
  }

  // 1) نفس منطق book (تحقق availability)
  const startDate = new Date(startAt);
  if (Number.isNaN(startDate.getTime())) {
    const err = new Error('Invalid startAt');
    err.status = 400;
    throw err;
  }

  const dateYmd = toYMD(startDate);
  const weekday = startDate.getDay();

  const override = await schedulesRepo.getOverrideByDate(appt.doctor_id, dateYmd);
  if (override && override.is_off === 1) {
    const err = new Error('Doctor is off on this date');
    err.status = 409;
    throw err;
  }

  let windows = [];
  if (override && override.start_time && override.end_time) {
    windows = [{ start: override.start_time, end: override.end_time }];
  } else {
    const weekly = await schedulesRepo.getWeeklyByWeekday(appt.doctor_id, weekday);
    windows = (weekly || []).map((w) => ({ start: w.start_time, end: w.end_time }));
  }

  if (windows.length === 0) {
    const err = new Error('Doctor not available on this day');
    err.status = 409;
    throw err;
  }

  const hhmm = startDate.toTimeString().slice(0, 5);
  const within = windows.some((w) => hhmm >= w.start.slice(0, 5) && hhmm < w.end.slice(0, 5));
  if (!within) {
    const err = new Error('Requested time outside working hours');
    err.status = 409;
    throw err;
  }

  // 2) تعارض المواعيد (مع استثناء نفس الموعد الحالي)
  const conflict = await appointmentsRepo.hasOverlapExcluding(
    appt.doctor_id,
    startDate,
    durationMinutes,
    apptId
  );
  if (conflict) {
    const err = new Error('Time slot already booked');
    err.status = 409;
    throw err;
  }

  // 3) Update
  return appointmentsRepo.reschedule(apptId, {
    startAt: startDate,
    durationMinutes,
    reason: reason ?? appt.reason
  });
},
async doctorAction(user, apptId, { status, note }) {
  const appt = await appointmentsRepo.findById(apptId);

  if (!appt || appt.doctor_id !== user.id) {
    const err = new Error('Appointment not found');
    err.status = 404;
    throw err;
  }

  if (appt.status !== 'BOOKED') {
    const err = new Error('Only BOOKED appointments can be updated');
    err.status = 409;
    throw err;
  }

  return appointmentsRepo.updateDoctorAction(apptId, status, note);
},
async setStatus(user, appointmentId, { status, doctorNote }) {
  // الطبيب فقط يعدّل مواعيده
  const ap = await appointmentsRepo.findById(appointmentId);
  if (!ap) {
    const err = new Error('Appointment not found');
    err.status = 404;
    throw err;
  }

  if (Number(ap.doctor_id) !== Number(user.id)) {
    const err = new Error('Forbidden');
    err.status = 403;
    throw err;
  }

  // يسمح فقط لو كان BOOKED
  if (ap.status !== 'BOOKED') {
    const err = new Error('Only BOOKED appointments can be updated');
    err.status = 409;
    throw err;
  }

  await appointmentsRepo.updateStatusAndNote(appointmentId, status, doctorNote ?? null);
  return appointmentsRepo.findById(appointmentId);
},

async setNote(user, appointmentId, { doctorNote }) {
  const ap = await appointmentsRepo.findById(appointmentId);
  if (!ap) {
    const err = new Error('Appointment not found');
    err.status = 404;
    throw err;
  }

  if (Number(ap.doctor_id) !== Number(user.id)) {
    const err = new Error('Forbidden');
    err.status = 403;
    throw err;
  }

  await appointmentsRepo.updateDoctorNote(appointmentId, doctorNote ?? null);
  return appointmentsRepo.findById(appointmentId);
},


};


module.exports = { appointmentsService };

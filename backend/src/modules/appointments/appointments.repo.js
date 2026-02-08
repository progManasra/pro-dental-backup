const { getPool } = require('../../db/pool');

const appointmentsRepo = {
  async listByDoctor(doctorId) {
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT a.id, a.start_at, a.status, a.duration_minutes, a.reason,
              a.doctor_note, a.updated_at, a.doctor_id, a.patient_id,
              u.full_name AS patient_name
       FROM appointments a
       JOIN users u ON u.id=a.patient_id
       WHERE a.doctor_id=?
       ORDER BY a.start_at DESC
       LIMIT 100`,
      [doctorId]
    );
    return rows;
  },

  async listByPatient(patientId) {
    const pool = getPool();
    const [rows] = await pool.query(
      `
      SELECT
        a.id,
        a.doctor_id,
        a.patient_id,
        a.start_at,
        a.duration_minutes,
        a.status,
        a.reason,
        a.doctor_note,
        a.updated_at,
        du.full_name AS doctor_name,
        pu.full_name AS patient_name
      FROM appointments a
      JOIN users du ON du.id = a.doctor_id
      JOIN users pu ON pu.id = a.patient_id
      WHERE a.patient_id=?
      ORDER BY a.start_at DESC
      `,
      [patientId]
    );
    return rows;
  },

  async hasOverlap(doctorId, startAt, durationMinutes) {
    const pool = getPool();

    const dayStart = new Date(startAt);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayEnd.getDate() + 1);

    const [rows] = await pool.query(
      `SELECT start_at, duration_minutes
       FROM appointments
       WHERE doctor_id=? AND status='BOOKED'
         AND start_at >= ? AND start_at < ?`,
      [doctorId, dayStart, dayEnd]
    );

    const a1 = startAt.getTime();
    const a2 = a1 + durationMinutes * 60000;

    return rows.some((r) => {
      const b1 = new Date(r.start_at).getTime();
      const b2 = b1 + Number(r.duration_minutes) * 60000;
      return a1 < b2 && b1 < a2;
    });
  },

  async create({ doctorId, patientId, startAt, durationMinutes, reason }) {
    const pool = getPool();
    const [r] = await pool.query(
      `INSERT INTO appointments(doctor_id,patient_id,start_at,status,duration_minutes,reason)
       VALUES (?,?,?,?,?,?)`,
      [doctorId, patientId, startAt, 'BOOKED', durationMinutes, reason]
    );
    return {
      id: r.insertId,
      doctorId,
      patientId,
      startAt,
      durationMinutes,
      status: 'BOOKED',
      reason
    };
  },

  async listMine(user, { status, from, to }) {
    const pool = getPool();

    let where = '';
    const params = [];

    if (user.role === 'DOCTOR') {
      where = 'WHERE a.doctor_id=?';
      params.push(user.id);
    } else if (user.role === 'PATIENT') {
      where = 'WHERE a.patient_id=?';
      params.push(user.id);
    } else {
      where = 'WHERE 1=0';
    }

    if (status) {
      where += ' AND a.status=?';
      params.push(status);
    }

    if (from) {
      where += ' AND DATE(a.start_at) >= ?';
      params.push(from);
    }

    if (to) {
      where += ' AND DATE(a.start_at) <= ?';
      params.push(to);
    }

    const [rows] = await pool.query(
      `
      SELECT
        a.id,
        a.doctor_id,
        a.patient_id,
        a.start_at,
        a.duration_minutes,
        a.status,
        a.reason,
        a.doctor_note,
        a.updated_at,
        du.full_name AS doctor_name,
        pu.full_name AS patient_name
      FROM appointments a
      JOIN users du ON du.id = a.doctor_id
      JOIN users pu ON pu.id = a.patient_id
      ${where}
      ORDER BY a.start_at DESC
      `,
      params
    );

    return rows;
  },

  async cancelByPatient(patientId, apptId) {
    const pool = getPool();
    const [r] = await pool.query(
      'UPDATE appointments SET status="CANCELLED" WHERE id=? AND patient_id=? AND status="BOOKED"',
      [apptId, patientId]
    );
    if (r.affectedRows === 0) {
      throw new Error('Cannot cancel this appointment');
    }
  },

  async listTakenSlots(doctorId, dateYmd) {
    const pool = getPool();
    const [rows] = await pool.query(
      'SELECT start_at FROM appointments WHERE doctor_id=? AND DATE(start_at)=? AND status="BOOKED"',
      [doctorId, dateYmd]
    );

    return new Set(
      rows.map((r) => {
        const d = new Date(r.start_at);
        const hh = String(d.getHours()).padStart(2, '0');
        const mm = String(d.getMinutes()).padStart(2, '0');
        return `${hh}:${mm}`;
      })
    );
  },

  // ✅ تعديل آمن: نخلي findById يرجع كمان doctor_id/patient_id/status + أسماء
  async findById(id) {
    const pool = getPool();
    const [rows] = await pool.query(
      `
      SELECT
        a.*,
        du.full_name AS doctor_name,
        pu.full_name AS patient_name
      FROM appointments a
      JOIN users du ON du.id = a.doctor_id
      JOIN users pu ON pu.id = a.patient_id
      WHERE a.id=? LIMIT 1
      `,
      [id]
    );
    return rows[0] || null;
  },

  async reschedule(id, { startAt, durationMinutes, reason }) {
    const pool = getPool();
    await pool.query(
      'UPDATE appointments SET start_at=?, duration_minutes=?, reason=? WHERE id=?',
      [startAt, durationMinutes, reason || null, id]
    );
    // ✅ نخليها ترجع نفس شكل findById
    return this.findById(id);
  },

  async hasOverlapExcluding(doctorId, startAt, durationMinutes, excludeId) {
    const pool = getPool();

    const start = new Date(startAt);
    const end = new Date(start.getTime() + durationMinutes * 60000);

    const [rows] = await pool.query(
      `
      SELECT id
      FROM appointments
      WHERE doctor_id=?
        AND status="BOOKED"
        AND id <> ?
        AND start_at < ?
        AND DATE_ADD(start_at, INTERVAL duration_minutes MINUTE) > ?
      LIMIT 1
      `,
      [doctorId, excludeId, end, start]
    );

    return rows.length > 0;
  },

  // ✅ موجود عندك — نخليه كما هو (ممتاز)
  async updateDoctorAction(id, status, note) {
    const pool = getPool();
    await pool.query(
      'UPDATE appointments SET status=?, doctor_note=? WHERE id=?',
      [status, note || null, id]
    );
    return this.findById(id);
  },

  // ✅ جديد: تحديث note فقط
  async updateDoctorNote(id, note) {
    const pool = getPool();
    await pool.query(
      'UPDATE appointments SET doctor_note=? WHERE id=?',
      [note || null, id]
    );
    return this.findById(id);
  },

  async listForBoardByDate(dateYmd) {
  const pool = getPool();
  const [rows] = await pool.query(
    `
    SELECT
      a.id,
      a.doctor_id,
      a.patient_id,
      a.start_at,
      a.status,
      a.duration_minutes,
      pu.full_name AS patient_name
    FROM appointments a
    JOIN users pu ON pu.id = a.patient_id
    WHERE DATE(a.start_at) = ?
    ORDER BY a.doctor_id, a.start_at
    `,
    [dateYmd]
  );
  return rows;
},

};

module.exports = { appointmentsRepo };

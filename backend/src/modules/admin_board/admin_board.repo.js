const { getPool } = require('../../db/pool');

const adminBoardRepo = {
  async listDoctors(doctorId) {
    const pool = getPool();
    if (doctorId) {
      const [rows] = await pool.query(
        `SELECT id, full_name
         FROM users
         WHERE role='DOCTOR' AND id=?`,
        [doctorId]
      );
      return rows;
    }

    const [rows] = await pool.query(
      `SELECT id, full_name
       FROM users
       WHERE role='DOCTOR'
       ORDER BY full_name ASC`
    );
    return rows;
  },

  async listWeeklyShiftsForWeekday(weekday, doctorIds) {
    const pool = getPool();
    if (!doctorIds.length) return [];

    const placeholders = doctorIds.map(() => '?').join(',');
    const [rows] = await pool.query(
      `
      SELECT id, doctor_id, weekday, start_time, end_time, slot_minutes
      FROM doctor_weekly_shifts
      WHERE weekday = ?
        AND doctor_id IN (${placeholders})
      ORDER BY doctor_id ASC
      `,
      [weekday, ...doctorIds]
    );
    return rows;
  },

  // إذا عندك جدول overrides (من عند setOverride)
  // افترضنا اسمه doctor_schedule_overrides
  // ولو اسم مختلف، غيّره هنا فقط.
  async listOverridesForDate(dateYmd, doctorIds) {
    const pool = getPool();
    if (!doctorIds.length) return [];

    const placeholders = doctorIds.map(() => '?').join(',');
    const [rows] = await pool.query(
      `
      SELECT id, doctor_id, date, is_off, start_time, end_time
      FROM doctor_schedule_overrides
      WHERE date = ?
        AND doctor_id IN (${placeholders})
      `,
      [dateYmd, ...doctorIds]
    );
    return rows;
  },

  async listAppointmentsForDate(dateYmd, doctorIds) {
    const pool = getPool();
    if (!doctorIds.length) return [];

    const placeholders = doctorIds.map(() => '?').join(',');
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
        pu.full_name AS patient_name,
        du.full_name AS doctor_name
      FROM appointments a
      JOIN users pu ON pu.id = a.patient_id
      JOIN users du ON du.id = a.doctor_id
      WHERE DATE(a.start_at) = ?
        AND a.doctor_id IN (${placeholders})
      ORDER BY a.start_at ASC
      `,
      [dateYmd, ...doctorIds]
    );
    return rows;
  },

  async getAppointmentDetails(id) {
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
      WHERE a.id=?
      LIMIT 1
      `,
      [id]
    );
    return rows[0] || null;
  },

  async adminCancelAppointment(id) {
    const pool = getPool();
    const [r] = await pool.query(
      `UPDATE appointments
       SET status='CANCELLED', updated_at=NOW()
       WHERE id=? AND status='BOOKED'`,
      [id]
    );
    return r.affectedRows > 0;
  },

  async adminRescheduleAppointment(id, startAt, durationMinutes, reason) {
    const pool = getPool();
    await pool.query(
      `UPDATE appointments
       SET start_at=?, duration_minutes=?, reason=?, updated_at=NOW()
       WHERE id=?`,
      [startAt, durationMinutes, reason || null, id]
    );
    const [rows] = await pool.query(
      `SELECT * FROM appointments WHERE id=? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }
};

module.exports = { adminBoardRepo };

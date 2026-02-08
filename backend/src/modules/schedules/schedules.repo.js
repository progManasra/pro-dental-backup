const { getPool } = require('../../db/pool');

const schedulesRepo = {
  async addWeeklyShift(doctorId, { weekday, startTime, endTime, slotMinutes }) {
    const pool = getPool();
    const [r] = await pool.query(
      `INSERT INTO doctor_weekly_shifts(doctor_id,weekday,start_time,end_time,slot_minutes)
       VALUES (?,?,?,?,?)`,
      [doctorId, weekday, startTime, endTime, slotMinutes]
    );
    return { id: r.insertId, doctorId, weekday, startTime, endTime, slotMinutes };
  },

  async upsertOverride(doctorId, { date, isOff, startTime, endTime }) {
    const pool = getPool();
    await pool.query(
      `INSERT INTO doctor_day_overrides(doctor_id,day_date,is_off,start_time,end_time)
       VALUES (?,?,?,?,?)
       ON DUPLICATE KEY UPDATE is_off=VALUES(is_off), start_time=VALUES(start_time), end_time=VALUES(end_time)`,
      [doctorId, date, isOff ? 1 : 0, startTime || null, endTime || null]
    );
    return { doctorId, date, isOff, startTime: startTime || null, endTime: endTime || null };
  },

  async getWeekly(doctorId) {
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT id, weekday, start_time, end_time, slot_minutes
       FROM doctor_weekly_shifts WHERE doctor_id=? ORDER BY weekday`,
      [doctorId]
    );
    return rows;
  },

  async getOverrides(doctorId) {
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT id, day_date, is_off, start_time, end_time
       FROM doctor_day_overrides WHERE doctor_id=? ORDER BY day_date DESC LIMIT 60`,
      [doctorId]
    );
    return rows;
  },

  async getOverrideByDate(doctorId, date) {
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT * FROM doctor_day_overrides WHERE doctor_id=? AND day_date=? LIMIT 1`,
      [doctorId, date]
    );
    return rows[0] || null;
  },

  async getWeeklyByWeekday(doctorId, weekday) {
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT * FROM doctor_weekly_shifts WHERE doctor_id=? AND weekday=? ORDER BY start_time`,
      [doctorId, weekday]
    );
    return rows;
  },

  async listWeekly() {
  const pool = getPool();
  const [rows] = await pool.query(`
    SELECT
      w.id,
      w.doctor_id,
      u.full_name AS doctor_name,
      w.weekday,
      w.start_time,
      w.end_time,
      w.slot_minutes
    FROM doctor_weekly_shifts w
    JOIN users u ON u.id = w.doctor_id
    ORDER BY u.full_name, w.weekday
  `);
  return rows;
},
async deleteWeekly(id) {
  const pool = getPool();
  await pool.query('DELETE FROM doctor_weekly_shifts WHERE id=?', [id]);
},
async createWeekly({ doctorId, weekday, startTime, endTime, slotMinutes }) {
  const pool = getPool();
  const [r] = await pool.query(
    `INSERT INTO doctor_weekly_shifts(doctor_id,weekday,start_time,end_time,slot_minutes)
     VALUES (?,?,?,?,?)`,
    [doctorId, weekday, startTime, endTime, slotMinutes || 30]
  );
  const [rows] = await pool.query('SELECT * FROM doctor_weekly_shifts WHERE id=?', [r.insertId]);
  return rows[0];
},

async updateWeekly(id, { startTime, endTime, slotMinutes }) {
  const pool = getPool();
  await pool.query(
    `UPDATE doctor_weekly_shifts SET start_time=?, end_time=?, slot_minutes=? WHERE id=?`,
    [startTime, endTime, slotMinutes || 30, id]
  );
  const [rows] = await pool.query('SELECT * FROM doctor_weekly_shifts WHERE id=?', [id]);
  return rows[0];
} ,

async deleteWeekly(id) {
  const pool = getPool();
  await pool.query('DELETE FROM doctor_weekly_shifts WHERE id=?', [id]);
}, 
async listDoctorsBasic() {
  const pool = getPool();
  const [rows] = await pool.query(
    "SELECT id, full_name FROM users WHERE role='DOCTOR' ORDER BY full_name"
  );
  return rows;
},



};

module.exports = { schedulesRepo };

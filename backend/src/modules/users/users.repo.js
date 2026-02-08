const { getPool } = require('../../db/pool');

const usersRepo = {
  async findByEmail(email) {
    const pool = getPool();
    const [rows] = await pool.query(
      'SELECT * FROM users WHERE email=? LIMIT 1',
      [email]
    );
    return rows[0] || null;
  },

  async list() {
    const pool = getPool();
    const [rows] = await pool.query(
      'SELECT id, full_name, email, role FROM users ORDER BY id DESC'
    );
    return rows;
  },

  async listByRole(role) {
    const pool = getPool();
    const [rows] = await pool.query(
      'SELECT id, full_name, email FROM users WHERE role=? ORDER BY full_name',
      [role]
    );
    return rows;
  },

  async create({ full_name, email, role, password_hash, specialization, dob }) {
    const pool = getPool();

    const [r] = await pool.query(
      'INSERT INTO users(full_name,email,role,password_hash) VALUES (?,?,?,?)',
      [full_name, email, role, password_hash]
    );

    const userId = r.insertId;

    if (role === 'DOCTOR') {
      await pool.query(
        'INSERT INTO doctors(user_id,specialization) VALUES (?,?)',
        [userId, specialization || 'General']
      );
    }

    if (role === 'PATIENT') {
      await pool.query(
        'INSERT INTO patients(user_id,dob) VALUES (?,?)',
        [userId, dob || null]
      );
    }

    return { id: userId, fullName: full_name, email, role };
  },

  async update(id, { full_name, email, role, password_hash, specialization, dob }) {
  const pool = getPool();

  // اقرأ الحالي أولاً
  const [curRows] = await pool.query(
    'SELECT id, full_name, email, role FROM users WHERE id=? LIMIT 1',
    [id]
  );
  const cur = curRows[0];
  if (!cur) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }

  // جهّز قيم مدموجة (لو الحقل مش موجود نخلي القديم)
  const nextFullName = (full_name !== undefined) ? full_name : cur.full_name;
  const nextEmail = (email !== undefined) ? email : cur.email;
  const nextRole = (role !== undefined) ? role : cur.role;

  // update users
  if (password_hash) {
    await pool.query(
      'UPDATE users SET full_name=?, email=?, role=?, password_hash=? WHERE id=?',
      [nextFullName, nextEmail, nextRole, password_hash, id]
    );
  } else {
    await pool.query(
      'UPDATE users SET full_name=?, email=?, role=? WHERE id=?',
      [nextFullName, nextEmail, nextRole, id]
    );
  }

  // ✅ doctor/patient extra tables (بشكل بسيط)
  if (nextRole === 'DOCTOR') {
    // upsert doctor row
    await pool.query(
      'INSERT INTO doctors(user_id,specialization) VALUES (?,?) ON DUPLICATE KEY UPDATE specialization=VALUES(specialization)',
      [id, (specialization !== undefined && specialization !== null && specialization !== '') ? specialization : 'General']
    );
    // لو كان مريض سابقاً، حذف بياناته
    await pool.query('DELETE FROM patients WHERE user_id=?', [id]);
  }

  if (nextRole === 'PATIENT') {
    await pool.query(
      'INSERT INTO patients(user_id,dob) VALUES (?,?) ON DUPLICATE KEY UPDATE dob=VALUES(dob)',
      [id, (dob !== undefined) ? dob : null]
    );
    await pool.query('DELETE FROM doctors WHERE user_id=?', [id]);
  }

  if (nextRole === 'ADMIN') {
    // admin ما يحتاج جداول فرعية
    await pool.query('DELETE FROM doctors WHERE user_id=?', [id]);
    await pool.query('DELETE FROM patients WHERE user_id=?', [id]);
  }

  return { id, fullName: nextFullName, email: nextEmail, role: nextRole };
},

async delete(id) {
  const pool = getPool();
  // حذف فرعي أولاً
  await pool.query('DELETE FROM doctors WHERE user_id=?', [id]);
  await pool.query('DELETE FROM patients WHERE user_id=?', [id]);
  // ثم users
  const [r] = await pool.query('DELETE FROM users WHERE id=?', [id]);
  if (r.affectedRows === 0) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }
  return true;
},

};

module.exports = { usersRepo };

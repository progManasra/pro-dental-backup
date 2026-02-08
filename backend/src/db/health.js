const { getPool } = require('./pool');

async function dbPing() {
  const pool = getPool();
  const [rows] = await pool.query('SELECT 1 AS ok');
  return rows?.[0]?.ok === 1;
}

module.exports = { dbPing };

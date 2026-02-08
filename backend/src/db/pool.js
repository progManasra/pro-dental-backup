const mysql = require('mysql2/promise');
const { env } = require('../config/env');
const { logger } = require('../logger');

let pool;

function getPool() {
  try {
    if (!pool) {
      pool = mysql.createPool({
        host: env.MYSQL_HOST,
        port: env.MYSQL_PORT,
        user: env.MYSQL_USER,
        password: env.MYSQL_PASSWORD,
        database: env.MYSQL_DB,
        waitForConnections: true,
        connectionLimit: 10
      });
      logger.info({ db: env.MYSQL_DB, host: env.MYSQL_HOST }, 'MySQL pool created');
    }
    return pool;
  } catch (err) {
    logger.error("DB connection failed", { error: err.message });
    throw err; // ✅ مهم للاختبارات
  }
}

// ✅ NEW: مفيد للاختبارات فقط
async function resetPool() {
  if (pool) {
    try { await pool.end(); } catch (_) {}
    pool = null;
  }
}

module.exports = { getPool, resetPool };

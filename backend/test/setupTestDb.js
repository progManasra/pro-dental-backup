// backend/test/setupTestDb.js
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

const host = process.env.MYSQL_HOST || '127.0.0.1';
const port = Number(process.env.MYSQL_PORT || 3306);
const user = process.env.MYSQL_USER || 'prodental';
const password = process.env.MYSQL_PASSWORD || 'prodental_pw';
const database = process.env.MYSQL_DB || 'prodental_test';

function readSql(relPath) {
  const p = path.resolve(__dirname, relPath);
  return fs.readFileSync(p, 'utf8');
}

async function run() {
  let conn;
  try {
    // ✅ اتصال بدون تحديد DB أولاً عشان نقدر نعمل CREATE DATABASE
    conn = await mysql.createConnection({ host, port, user, password, multipleStatements: true });

    // ✅ أنشئ DB للاختبار
    // await conn.query(`CREATE DATABASE IF NOT EXISTS \`${database}\``);
    // await conn.query(`USE \`${database}\``);
conn = await mysql.createConnection({ host, port, user, password, database, multipleStatements: true });

    // ✅ استخدم نفس ملفات المشروع الموجودة في db/
const schemaSql = readSql('./schema.sql');
const seedSql = readSql('./seed.sql');

    await conn.query(schemaSql);
    await conn.query(seedSql);

    console.log('[TEST-DB] ready:', { host, port, user, database });
    await conn.end();
    process.exit(0);
  } catch (e) {
    console.error('[TEST-DB] setup failed', e);
    try { if (conn) await conn.end(); } catch (_) {}
    process.exit(1);
  }
}

run();

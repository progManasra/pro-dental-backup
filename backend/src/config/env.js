function must(name, fallback) {
  const v = process.env[name] ?? fallback;
  if (v === undefined || v === null || v === '') throw new Error(`Missing env: ${name}`);
  return v;
}

const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',

  API_PORT: Number(must('API_PORT', '8091')),

  MYSQL_HOST: must('MYSQL_HOST', 'mysql'),
  MYSQL_PORT: Number(must('MYSQL_PORT', '3306')),
  MYSQL_DB: must('MYSQL_DB', 'prodental'),
  MYSQL_USER: must('MYSQL_USER', 'prodental'),
  MYSQL_PASSWORD: must('MYSQL_PASSWORD', 'prodental_pw'),

  JWT_SECRET: must('JWT_SECRET', 'change_me'),
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d'
};

module.exports = { env };

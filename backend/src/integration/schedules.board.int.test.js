const request = require('supertest');

process.env.MYSQL_DB = process.env.MYSQL_DB || 'prodental_test';

// ✅ Mock auth + rbac فقط (عشان ما ندخل قصة JWT بالتست)
jest.mock('../middlewares/auth', () => ({
  authRequired: () => (req, _res, next) => {
    req.user = { id: 1, role: 'ADMIN' };
    next();
  }
}));

jest.mock('../middlewares/rbac', () => ({
  requireRoles: () => (_req, _res, next) => next()
}));

const { createApp } = require('../app');
const { resetPool } = require('../db/pool');

describe('Integration: GET /api/v1/schedules/board', () => {
  afterAll(async () => {
    if (resetPool) await resetPool();
  });

  it('returns BOOKED slot with patientName (real DB)', async () => {
    const app = createApp();

    const res = await request(app)
      .get('/api/v1/schedules/board?date=2026-01-29')
      .expect(200);

    expect(res.body.ok).toBe(true);
    expect(res.body.date).toBe('2026-01-29');

    // حسب مثال بياناتك: Dr A id=5
    const dr = (res.body.doctors || []).find((d) => d.doctorId === 5);
    expect(dr).toBeTruthy();

    // مثال: booked 09:30
    const slot = (dr.slots || []).find((s) => s.time === '09:30');
    expect(slot).toBeTruthy();
    expect(slot.status).toBe('BOOKED');
    expect(slot.patientName).toBeTruthy();
  });
});

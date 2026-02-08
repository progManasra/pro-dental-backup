const express = require('express');
const { z } = require('zod');
const { authRequired } = require('../../middlewares/auth');
const { requireRoles } = require('../../middlewares/rbac');
const { validate } = require('../../middlewares/validate');
const controller = require('./schedules.controller');

const router = express.Router();

/**
 * @openapi
 * /api/v1/schedules/weekly/{doctorId}:
 *   post:
 *     tags: [Schedules]
 */
router.post(
  '/weekly/:doctorId',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    params: z.object({ doctorId: z.coerce.number().int().positive() }),
    body: z.object({
      weekday: z.number().int().min(0).max(6),
      startTime: z.string(),
      endTime: z.string(),
      slotMinutes: z.number().int().min(10).max(120).default(30)
    })
  }),
  controller.addWeeklyShift
);

router.post(
  '/override/:doctorId',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    params: z.object({ doctorId: z.coerce.number().int().positive() }),
    body: z.object({
      date: z.string(), // YYYY-MM-DD
      isOff: z.boolean(),
      startTime: z.string().optional(),
      endTime: z.string().optional()
    })
  }),
  controller.setOverride
);

router.get(
  '/doctor/:doctorId',
  authRequired(),
  requireRoles('ADMIN', 'DOCTOR'),
  validate({ params: z.object({ doctorId: z.coerce.number().int().positive() }) }),
  controller.getDoctorSchedule
);

router.get(
  '/weekly',
  authRequired(),
  requireRoles('ADMIN'),
  controller.listWeekly
);
router.post(
  '/:id/delete',
  authRequired(),
  requireRoles('ADMIN'),
  controller.deleteWeekly
);
router.get('/weekly', authRequired(), requireRoles('ADMIN'), controller.listWeekly);

router.post(
  '/weekly',
  authRequired(),
  requireRoles('ADMIN'),
  controller.createWeekly
);

router.put(
  '/weekly/:id',
  authRequired(),
  requireRoles('ADMIN'),
  controller.updateWeekly
);

router.delete(
  '/weekly/:id',
  authRequired(),
  requireRoles('ADMIN'),
  controller.deleteWeekly
);

// Admin daily board (grid)
router.get(
  '/board',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    query: z.object({
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/) // YYYY-MM-DD
    })
  }),
  controller.dailyBoard
);


module.exports = router;

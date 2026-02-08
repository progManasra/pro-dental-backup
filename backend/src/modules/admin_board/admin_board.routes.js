const express = require('express');
const { z } = require('zod');
const { authRequired } = require('../../middlewares/auth');
const { requireRoles } = require('../../middlewares/rbac');
const { validate } = require('../../middlewares/validate');
const controller = require('./admin_board.controller');

const router = express.Router();

/**
 * GET /api/v1/admin/schedule-board?date=YYYY-MM-DD&doctorId=#
 * يرجع Grid + Stats
 */
router.get(
  '/schedule-board',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    query: z.object({
      date: z.string().min(10),
      doctorId: z.coerce.number().int().positive().optional()
    })
  }),
  controller.getBoard
);

/**
 * Click on slot => appointment details
 */
router.get(
  '/appointments/:id',
  authRequired(),
  requireRoles('ADMIN'),
  validate({ params: z.object({ id: z.coerce.number().int().positive() }) }),
  controller.getAppointmentDetails
);

/**
 * Cancel appointment (ADMIN)
 */
router.post(
  '/appointments/:id/cancel',
  authRequired(),
  requireRoles('ADMIN'),
  validate({ params: z.object({ id: z.coerce.number().int().positive() }) }),
  controller.cancelAppointment
);

/**
 * Reschedule appointment (ADMIN)
 * body: { startAt: ISO, durationMinutes?: number, reason?: string }
 */
router.put(
  '/appointments/:id/reschedule',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    params: z.object({ id: z.coerce.number().int().positive() }),
    body: z.object({
      startAt: z.string().min(10),
      durationMinutes: z.coerce.number().int().min(10).max(240).optional(),
      reason: z.string().optional()
    })
  }),
  controller.rescheduleAppointment
);

module.exports = router;

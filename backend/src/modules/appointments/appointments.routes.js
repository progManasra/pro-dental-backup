const express = require('express');
const { z } = require('zod');
const { authRequired } = require('../../middlewares/auth');
const { requireRoles } = require('../../middlewares/rbac');
const { validate } = require('../../middlewares/validate');
const controller = require('./appointments.controller');

const router = express.Router();

router.get('/me',authRequired(),requireRoles('DOCTOR', 'PATIENT'),controller.myAppointments);

router.post(
  '/book',
  authRequired(),
  requireRoles('PATIENT'),
  validate({
    body: z.object({
      doctorId: z.number().int().positive(),
      startAt: z.string(), // ISO datetime
      durationMinutes: z.number().int().min(10).max(120).default(30),
      reason: z.string().optional()
    })
  }),
  controller.book
);

router.get(
  '/available',
  authRequired(),
  requireRoles('PATIENT'),
  controller.availableSlots
);
router.post(
  '/:id/doctor-action',
  authRequired(),
  requireRoles('DOCTOR'),
  validate({
    body: z.object({
      status: z.enum(['COMPLETED', 'NO_SHOW']),
      note: z.string().optional()
    })
  }),
  controller.doctorAction
);

router.post(
  '/:id/reschedule',
  authRequired(),
  requireRoles('PATIENT'),
  validate({
    body: z.object({
      startAt: z.string(), // ISO
      durationMinutes: z.number().int().min(10).max(120).default(30),
      reason: z.string().optional()
    })
  }),
  controller.reschedule
);

router.post(
  '/:id/cancel',
  authRequired(),
  requireRoles('PATIENT'),
  controller.cancel
);

router.put(
  '/:id/status',
  authRequired(),
  requireRoles('DOCTOR'),
  validate({
    params: z.object({ id: z.coerce.number().int().positive() }),
    body: z.object({
      status: z.enum(['COMPLETED', 'NO_SHOW']),
      doctorNote: z.string().optional()
    })
  }),
  controller.setStatus
);

router.put(
  '/:id/note',
  authRequired(),
  requireRoles('DOCTOR'),
  validate({
    params: z.object({ id: z.coerce.number().int().positive() }),
    body: z.object({
      doctorNote: z.string().optional()
    })
  }),
  controller.setNote
);


module.exports = router;

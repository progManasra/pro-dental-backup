const express = require('express');
const { z } = require('zod');
const { authRequired } = require('../../middlewares/auth');
const { requireRoles } = require('../../middlewares/rbac');
const { validate } = require('../../middlewares/validate');
const controller = require('./users.controller');

const router = express.Router();

/**
 * @openapi
 * /api/v1/users:
 *   get:
 *     tags: [Users]
 *     summary: List all users
 *     responses:
 *       200:
 *         description: OK
 */
router.get(
  '/',
  authRequired(),
requireRoles('ADMIN', 'PATIENT', 'DOCTOR'),
  controller.listUsers
);

/**
 * @openapi
 * /api/v1/users/by-role/{role}:
 *   get:
 *     tags: [Users]
 *     summary: List users by role
 *     parameters:
 *       - in: path
 *         name: role
 *         required: true
 *         schema:
 *           type: string
 *           enum: [ADMIN, DOCTOR, PATIENT]
 *     responses:
 *       200:
 *         description: OK
 */
router.get(
  '/by-role/:role',
  authRequired(),
requireRoles('ADMIN', 'PATIENT', 'DOCTOR'),
  controller.listUsersByRole
);

/**
 * @openapi
 * /api/v1/users:
 *   post:
 *     tags: [Users]
 *     summary: Create user
 *     responses:
 *       201:
 *         description: Created
 */
router.post(
  '/',
  authRequired(),
requireRoles('ADMIN', 'PATIENT', 'DOCTOR'),
  validate({
    body: z.object({
      fullName: z.string().min(2),
      email: z.string().email(),
      role: z.enum(['ADMIN', 'DOCTOR', 'PATIENT']),
      password: z.string().min(4),
      specialization: z.string().optional(),
      dob: z.string().optional()
    })
  }),
  controller.createUser
);
// UPDATE user
router.put(
  '/:id',
  authRequired(),
  requireRoles('ADMIN'),
  validate({
    params: z.object({ id: z.coerce.number().int().positive() }),
    body: z.object({
      fullName: z.string().min(2).optional(),
      email: z.string().email().optional(),
      role: z.enum(['ADMIN', 'DOCTOR', 'PATIENT']).optional(),
      password: z.string().min(4).optional(),
      specialization: z.string().nullable().optional(),
      dob: z.string().nullable().optional(),
    })
  }),
  controller.updateUser
);

// DELETE user
router.delete(
  '/:id',
  authRequired(),
  requireRoles('ADMIN'),
  validate({ params: z.object({ id: z.coerce.number().int().positive() }) }),
  controller.deleteUser
);

module.exports = router;

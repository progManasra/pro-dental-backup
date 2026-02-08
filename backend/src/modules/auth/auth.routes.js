const express = require('express');
const { z } = require('zod');
const { validate } = require('../../middlewares/validate');
const { login } = require('./auth.controller');

const router = express.Router();

/**
 * @openapi
 * /api/v1/auth/login:
 *   post:
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: OK
 */
router.post(
  '/login',
  validate({
    body: z.object({
      email: z.string().email(),
      password: z.string().min(4)
    })
  }),
  login
);

module.exports = router;

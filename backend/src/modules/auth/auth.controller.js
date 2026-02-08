const { authService } = require('./auth.service');

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    const out = await authService.login(email, password);
    res.json({ ok: true, ...out });
  } catch (e) {
    e.status = e.status || 400;
    next(e);
  }
}

module.exports = { login };

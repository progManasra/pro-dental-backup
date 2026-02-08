const jwt = require('jsonwebtoken');
const { env } = require('../config/env');

function authRequired() {
  return (req, res, next) => {
    const h = req.headers.authorization || '';
    const token = h.startsWith('Bearer ') ? h.slice(7) : null;
    if (!token) return res.status(401).json({ ok: false, error: 'Missing token' });

    try {
      const payload = jwt.verify(token, env.JWT_SECRET);
      req.user = payload; // { id, role, email, name }
      next();
    } catch {
      return res.status(401).json({ ok: false, error: 'Invalid token' });
    }
  };
}

module.exports = { authRequired };

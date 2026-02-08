const logger = require('../utils/logger');

function requireRoles(...roles) {
  return (req, res, next) => {
    if (!req.user?.role) {
      logger.warn('Attempted access without role', { userId: req.user?.id, requiredRoles: roles });
      return res.status(401).json({ ok: false, message: 'Unauthorized' });
    }

    if (!roles.includes(req.user.role)) {
      logger.warn('Forbidden role access', { userId: req.user.id, role: req.user.role, requiredRoles: roles });
      return res.status(403).json({ ok: false, message: 'Forbidden' });
    }

    next();
  };
}

module.exports = { requireRoles };

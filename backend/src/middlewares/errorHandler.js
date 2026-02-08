const { logger } = require('../logger');

function errorHandler() {
  return (err, req, res, next) => {
    logger.error({ err, path: req.path }, 'Unhandled error');
    const status = err.status || 500;
    res.status(status).json({
      ok: false,
      error: err.message || 'Internal Server Error'
    });
  };
}

module.exports = { errorHandler };

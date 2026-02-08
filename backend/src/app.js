const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { errorHandler } = require('./middlewares/errorHandler');
const { setupSwagger } = require('./config/swagger');
const { dbPing } = require('./db/health');
const adminBoardRoutes = require('./modules/admin_board/admin_board.routes');


function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  setupSwagger(app);

  app.get('/health', async (req, res) => {
    const dbOk = await dbPing().catch(() => false);
    res.json({ ok: true, db: dbOk });
  });

  app.use('/api/v1/auth', require('./modules/auth/auth.routes'));
  app.use('/api/v1/users', require('./modules/users/users.routes'));
  app.use('/api/v1/schedules', require('./modules/schedules/schedules.routes'));
  app.use('/api/v1/appointments', require('./modules/appointments/appointments.routes'));
  app.use('/api/v1/admin', adminBoardRoutes);

  app.use(errorHandler());
  return app;
}

module.exports = { createApp };

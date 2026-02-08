const { createApp } = require('./app');
const { env } = require('./config/env');
const { logger } = require('./logger');

const app = createApp();

app.listen(env.API_PORT, () => {
  logger.info({ port: env.API_PORT }, 'Backend running');
});

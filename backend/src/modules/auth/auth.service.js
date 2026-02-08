const jwt = require('jsonwebtoken');
const { env } = require('../../config/env');
const { verifyPassword } = require('../../utils/crypto');
const { usersRepo } = require('../users/users.repo');

const authService = {
  async login(email, password) {
    const user = await usersRepo.findByEmail(email);
    if (!user) {
      const err = new Error('Invalid credentials');
      err.status = 401;
      throw err;
    }
    const ok = await verifyPassword(password, user.password_hash);
    if (!ok) {
      const err = new Error('Invalid credentials');
      err.status = 401;
      throw err;
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email, name: user.full_name },
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRES_IN }
    );
const logger = require('../../utils/logger');

logger.info("User logged in", {
  userId: user.id,
  role: user.role
});

    return {
      token,
      user: { id: user.id, role: user.role, email: user.email, fullName: user.full_name }
    };
  }
  
};


module.exports = { authService };

const { hashPassword } = require('../../utils/crypto');
const { usersRepo } = require('./users.repo');

const usersService = {
  async list() {
    return usersRepo.list();
  },

  async listByRole(role) {
    return usersRepo.listByRole(role);
  },

  async create(input) {
    const password_hash = await hashPassword(input.password);

    return usersRepo.create({
      full_name: input.fullName,
      email: input.email,
      role: input.role,
      password_hash,
      specialization: input.specialization,
      dob: input.dob
    });
  },

  // ✅ NEW
  async updateUser(id, input) {
    let password_hash = null;
    if (input.password) password_hash = await hashPassword(input.password);

    return usersRepo.update(id, {
      full_name: input.fullName,
      email: input.email,
      role: input.role,
      password_hash,
      specialization: input.specialization,
      dob: input.dob
    });
  },

  // ✅ NEW
  async deleteUser(id) {
    return usersRepo.delete(id);
  }
};

module.exports = { usersService };

const { z } = require('zod');
const { usersRepo } = require('../../modules/users/users.repo');
const { hashPassword } = require('../../utils/crypto');

function createUserCmd(program) {
  program
    .command('create-user')
    .requiredOption('--name <name>')
    .requiredOption('--email <email>')
    .requiredOption('--role <role>')
    .requiredOption('--password <password>')
    .option('--specialization <specialization>')
    .option('--dob <dob>')
    .action(async (opts) => {
      const schema = z.object({
        name: z.string().min(2),
        email: z.string().email(),
        role: z.enum(['ADMIN', 'DOCTOR', 'PATIENT']),
        password: z.string().min(4),
        specialization: z.string().optional(),
        dob: z.string().optional()
      });

      const v = schema.parse({
        name: opts.name,
        email: opts.email,
        role: opts.role,
        password: opts.password,
        specialization: opts.specialization,
        dob: opts.dob
      });

      const password_hash = await hashPassword(v.password);
      const user = await usersRepo.create({
        full_name: v.name,
        email: v.email,
        role: v.role,
        password_hash,
        specialization: v.specialization,
        dob: v.dob
      });

      console.log('Created:', user);
      process.exit(0);
    });
}

module.exports = { createUserCmd };

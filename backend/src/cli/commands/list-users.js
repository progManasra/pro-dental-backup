const { usersRepo } = require('../../modules/users/users.repo');

function listUsersCmd(program) {
  program.command('list-users').action(async () => {
    const users = await usersRepo.list();
    console.table(users);
    process.exit(0);
  });
}

module.exports = { listUsersCmd };

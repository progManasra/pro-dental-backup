const { Command } = require('commander');
const { createUserCmd } = require('./commands/create-user');
const { listUsersCmd } = require('./commands/list-users');

const program = new Command();
program.name('prodental').description('ProDental CLI').version('1.0.0');

createUserCmd(program);
listUsersCmd(program);

program.parse(process.argv);

const { usersService } = require('./users.service');

async function listUsers(req, res, next) {
  try {
    const rows = await usersService.list();
    res.json({ ok: true, items: rows });
  } catch (e) {
    next(e);
  }
}

async function createUser(req, res, next) {
  try {
    const out = await usersService.create(req.body);
    res.status(201).json({ ok: true, user: out });
  } catch (e) {
    next(e);
  }
}

async function listUsersByRole(req, res, next) {
  try {
    const { role } = req.params;
    const rows = await usersService.listByRole(role);
    res.json({ ok: true, items: rows });
  } catch (e) {
    next(e);
  }
}

async function updateUser(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await usersService.updateUser(id, req.body);
    res.json({ ok: true, user: out });
  } catch (e) { next(e); }
}

async function deleteUser(req, res, next) {
  try {
    const id = Number(req.params.id);
    await usersService.deleteUser(id);
    res.json({ ok: true });
  } catch (e) { next(e); }
}

module.exports = { listUsers, listUsersByRole, createUser, updateUser, deleteUser };


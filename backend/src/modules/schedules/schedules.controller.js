const { schedulesService } = require('./schedules.service');

async function addWeeklyShift(req, res, next) {
  try {
    const out = await schedulesService.addWeeklyShift(req.params.doctorId, req.body);
    res.status(201).json({ ok: true, shift: out });
  } catch (e) {
    next(e);
  }
}

async function setOverride(req, res, next) {
  try {
    const out = await schedulesService.setOverride(req.params.doctorId, req.body);
    res.status(201).json({ ok: true, override: out });
  } catch (e) {
    next(e);
  }
}

async function getDoctorSchedule(req, res, next) {
  try {
    const out = await schedulesService.getDoctorSchedule(req.params.doctorId);
    res.json({ ok: true, ...out });
  } catch (e) {
    next(e);
  }
}

async function listWeekly(req, res, next) {
  try {
    const rows = await schedulesService.listWeekly();
    res.json({ ok: true, items: rows });
  } catch (e) {
    next(e);
  }
}

async function deleteWeekly(req, res, next) {
  try {
    const id = Number(req.params.id);
    await schedulesService.deleteWeekly(id);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}

// create weekly via /schedules/weekly
async function createWeekly(req, res, next) {
  try {
    const out = await schedulesService.createWeekly(req.body);
    res.status(201).json({ ok: true, shift: out });
  } catch (e) {
    next(e);
  }
}

// update weekly via PUT /schedules/weekly/:id
async function updateWeekly(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await schedulesService.updateWeekly(id, req.body);
    res.json({ ok: true, shift: out });
  } catch (e) {
    next(e);
  }
}

// ✅ Admin daily board
async function dailyBoard(req, res, next) {
  try {
    const { date } = req.query; // YYYY-MM-DD
    const out = await schedulesService.dailyBoard(date);
    res.json({ ok: true, ...out });
  } catch (e) {
    next(e);
  }
}

module.exports = {
  addWeeklyShift,
  setOverride,
  getDoctorSchedule,
  listWeekly,
  deleteWeekly,
  createWeekly,
  updateWeekly,
  dailyBoard,
};

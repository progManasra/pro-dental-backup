const { adminBoardService } = require('./admin_board.service');

async function getBoard(req, res, next) {
  try {
    const date = String(req.query.date || '').trim();
    const doctorId = req.query.doctorId ? Number(req.query.doctorId) : null;

    if (!date) throw new Error('date is required (YYYY-MM-DD)');

    const out = await adminBoardService.getBoard({ dateYmd: date, doctorId });
    res.json(out);
  } catch (e) {
    next(e);
  }
}

async function getAppointmentDetails(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await adminBoardService.getAppointmentDetails(id);
    res.json({ ok: true, item: out });
  } catch (e) {
    next(e);
  }
}

async function cancelAppointment(req, res, next) {
  try {
    const id = Number(req.params.id);
    await adminBoardService.cancelAppointment(id);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}

async function rescheduleAppointment(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await adminBoardService.rescheduleAppointment(id, req.body || {});
    res.json({ ok: true, item: out });
  } catch (e) {
    next(e);
  }
}

module.exports = {
  getBoard,
  getAppointmentDetails,
  cancelAppointment,
  rescheduleAppointment
};

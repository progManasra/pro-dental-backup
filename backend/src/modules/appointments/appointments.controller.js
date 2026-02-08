const logger = require('../../utils/logger');

const { appointmentsService } = require('./appointments.service');

async function myAppointments(req, res, next) {
  try {
    const status = req.query.status ? String(req.query.status) : null;
    const from = req.query.from ? String(req.query.from) : null;
    const to = req.query.to ? String(req.query.to) : null;

    const out = await appointmentsService.myAppointments(req.user, { status, from, to });
    res.json({ ok: true, items: out });
  } catch (e) {
    next(e);
  }
}


async function book(req, res, next) {
  try {
    logger.debug({ body: req.body }, 'Booking payload'); // ✅ هنا مكانه الصحيح
    const out = await appointmentsService.book(req.user, req.body);
    res.status(201).json({ ok: true, appointment: out });
  } catch (e) {
    next(e);
  }
}

async function availableSlots(req, res, next) {
  try {
    const doctorId = Number(req.query.doctorId);
    const date = String(req.query.date); // YYYY-MM-DD
    const out = await appointmentsService.availableSlots({ doctorId, date });
    res.json({ ok: true, ...out });
  } catch (e) {
    next(e);
  }
}
async function cancel(req, res, next) {
  try {
    const id = Number(req.params.id);
    await appointmentsService.cancel(req.user, id);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}
async function reschedule(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await appointmentsService.reschedule(req.user, id, req.body);
    res.json({ ok: true, appointment: out });
  } catch (e) {
    next(e);
  }
}
async function doctorAction(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await appointmentsService.doctorAction(req.user, id, req.body);
    res.json({ ok: true, appointment: out });
  } catch (e) {
    next(e);
  }
}


async function setStatus(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await appointmentsService.setStatus(req.user, id, req.body);
    res.json({ ok: true, appointment: out });
  } catch (e) { next(e); }
}

async function setNote(req, res, next) {
  try {
    const id = Number(req.params.id);
    const out = await appointmentsService.setNote(req.user, id, req.body);
    res.json({ ok: true, appointment: out });
  } catch (e) { next(e); }
}

module.exports = { myAppointments, book, availableSlots, cancel, reschedule, doctorAction, setStatus, setNote };
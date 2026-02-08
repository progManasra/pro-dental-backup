function validate({ body, query, params }) {
  return (req, res, next) => {
    try {
      if (body) req.body = body.parse(req.body);
      if (query) req.query = query.parse(req.query);
      if (params) req.params = params.parse(req.params);
      next();
    } catch (e) {
      return res.status(400).json({ ok: false, error: e.errors?.[0]?.message || 'Validation error' });
    }
  };
}

module.exports = { validate };

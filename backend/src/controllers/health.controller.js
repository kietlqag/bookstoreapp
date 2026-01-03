function healthCheck(_req, res) {
  res.json({ ok: true });
}

module.exports = { healthCheck };

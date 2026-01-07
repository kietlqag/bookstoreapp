const { chatWithAI } = require('../services/chat.service');

async function chat(req, res, next) {
  try {
    const { messages } = req.body || {};

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        message: 'Messages array is required.',
      });
    }

    // Validate message format
    for (const msg of messages) {
      if (!msg.role || !msg.content) {
        return res.status(400).json({
          message: 'Each message must have role and content.',
        });
      }
      if (!['user', 'assistant'].includes(msg.role)) {
        return res.status(400).json({
          message: 'Message role must be "user" or "assistant".',
        });
      }
    }

    const response = await chatWithAI(messages);
    return res.json({
      message: response.message,
      suggestedBooks: response.suggestedBooks || [],
      suggestedVouchers: response.suggestedVouchers || [],
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { chat };

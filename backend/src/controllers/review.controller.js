const reviewService = require('../services/review.service');

async function listReviews(req, res, next) {
  try {
    const orderId = Number(req.query.orderId);
    const userId = Number(req.query.userId);
    if (Number.isInteger(orderId) && Number.isInteger(userId)) {
      const reviews = await reviewService.listByOrder(orderId, userId);
      return res.json(reviews);
    }

    const bookId = Number(req.query.bookId);
    if (!Number.isInteger(bookId)) {
      return res.status(400).json({ message: 'Invalid book id.' });
    }
    const reviews = await reviewService.listByBook(bookId);
    return res.json(reviews);
  } catch (error) {
    return next(error);
  }
}

async function createReview(req, res, next) {
  try {
    const {
      orderId,
      orderItemId,
      bookId,
      userId,
      userName,
      rating,
      comment,
      anonymous,
      images,
      videos,
    } = req.body || {};
    const parsedOrderId = Number(orderId);
    const parsedOrderItemId = Number(orderItemId);
    const parsedBookId = Number(bookId);
    const parsedUserId = Number(userId);
    const parsedRating = Number(rating);

    if (!Number.isInteger(parsedOrderId) ||
        !Number.isInteger(parsedOrderItemId) ||
        !Number.isInteger(parsedBookId) ||
        !Number.isFinite(parsedRating) ||
        parsedRating < 1 ||
        parsedRating > 5 ||
        !Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid review payload.' });
    }

    const safeComment = comment?.toString().trim() ?? '';
    const safeAnonymous = anonymous == true;
    const safeImages = Array.isArray(images)
      ? images.filter((item) => typeof item === 'string')
      : [];
    const safeVideos = Array.isArray(videos)
      ? videos.filter((item) => typeof item === 'string')
      : [];

    const result = await reviewService.createReview({
      orderId: parsedOrderId,
      orderItemId: parsedOrderItemId,
      bookId: parsedBookId,
      userId: parsedUserId,
      userName: safeAnonymous ? null : userName?.toString(),
      rating: parsedRating,
      comment: safeComment,
      anonymous: safeAnonymous,
      images: safeImages,
      videos: safeVideos,
    });

    return res.json({
      reviewId: result.reviewId,
      remaining: result.remaining,
    });
  } catch (error) {
    return next(error);
  }
}

async function updateReview(req, res, next) {
  try {
    const reviewId = Number(req.params.id);
    const {
      userId,
      userName,
      rating,
      comment,
      anonymous,
      images,
      videos,
    } = req.body || {};
    const parsedUserId = Number(userId);
    const parsedRating = Number(rating);

    if (!Number.isInteger(reviewId) ||
        !Number.isInteger(parsedUserId) ||
        !Number.isFinite(parsedRating) ||
        parsedRating < 1 ||
        parsedRating > 5) {
      return res.status(400).json({ message: 'Invalid review payload.' });
    }

    const safeComment = comment?.toString().trim() ?? '';
    const safeAnonymous = anonymous == true;
    const safeImages = Array.isArray(images)
      ? images.filter((item) => typeof item === 'string')
      : [];
    const safeVideos = Array.isArray(videos)
      ? videos.filter((item) => typeof item === 'string')
      : [];

    const result = await reviewService.updateReview({
      reviewId,
      userId: parsedUserId,
      userName: safeAnonymous ? null : userName?.toString(),
      rating: parsedRating,
      comment: safeComment,
      anonymous: safeAnonymous,
      images: safeImages,
      videos: safeVideos,
    });

    return res.json({ reviewId: result.reviewId });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listReviews,
  createReview,
  updateReview,
};

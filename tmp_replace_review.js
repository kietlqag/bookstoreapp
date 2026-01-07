const fs = require('fs');
const path = 'bookstore_app/lib/screens/review_order_page.dart';
const text = fs.readFileSync(path, 'utf8');
const start = text.indexOf('  Future<void> _submitReview() async {');
const end = text.indexOf('  Future<void> _pickImage', start);
if (start === -1 || end === -1) {
  throw new Error('markers not found');
}
const newBlock = `  Future<void> _submitReview() async {
    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      _showMessage('Không có sản phẩm để đánh giá.');
      return;
    }
    final trimmedComment = _commentController.text.trim();
    if (trimmedComment.length < _minChars) {
      _showMessage('Vui lòng nhập tối thiểu \$_minChars ký tự.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userName = widget.order.recipientName.isNotEmpty
          ? widget.order.recipientName
          : 'Khách hàng';
      final remaining = await widget.reviewService.submitReview(
        orderId: widget.order.id,
        orderItemId: selectedItem.id,
        bookId: selectedItem.bookId,
        userId: widget.userId,
        userName: userName,
        rating: _productRating,
        comment: trimmedComment,
        anonymous: _anonymous,
        images: _selectedImages.map((file) => file.path).toList(),
        videos: _selectedVideos.map((file) => file.path).toList(),
      );

      setState(() {
        _selectedImages.clear();
        _selectedVideos.clear();
        _productRating = 5;
        _commentController.clear();
        _commentLength = 0;
      });

      if (remaining == 0) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _pendingItems.removeAt(_safeIndex);
        if (_selectedProductIndex >= _pendingItems.length) {
          _selectedProductIndex =
              _pendingItems.isEmpty ? 0 : _pendingItems.length - 1;
        }
      });
      _showMessage('Đã gửi đánh giá. Còn \$remaining sản phẩm chưa đánh giá.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

`;
const replaced = text.slice(0, start) + newBlock + text.slice(end);
fs.writeFileSync(path, 'utf8');

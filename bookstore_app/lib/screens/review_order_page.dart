import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../models/order.dart';
import '../models/review_service.dart';
import '../widgets/app_colors.dart';

class ReviewOrderPage extends StatefulWidget {
  const ReviewOrderPage({
    super.key,
    required this.order,
    required this.userId,
    required this.reviewService,
  });

  final OrderSummary order;
  final int userId;
  final ReviewService reviewService;

  @override
  State<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends State<ReviewOrderPage> {
  static const int _minChars = 50;
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];
  late List<OrderItemSummary> _pendingItems;
  int _productRating = 5;
  int _selectedProductIndex = 0;
  int _commentLength = 0;
  bool _anonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pendingItems = widget.order.items.where((item) => !item.reviewed).toList();
    _commentController.addListener(() {
      setState(() {
        _commentLength = _commentController.text.trim().length;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  OrderItemSummary? get _selectedItem {
    if (_pendingItems.isEmpty) return null;
    final safeIndex = _selectedProductIndex.clamp(0, _pendingItems.length - 1);
    return _pendingItems[safeIndex];
  }

  int get _safeIndex {
    if (_pendingItems.isEmpty) return 0;
    return _selectedProductIndex.clamp(0, _pendingItems.length - 1);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitReview() async {
    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      _showMessage('Kh�ng c� s?n ph?m d? d�nh gi�.');
      return;
    }
    final trimmedComment = _commentController.text.trim();
    if (trimmedComment.length < _minChars) {
      _showMessage('Vui l�ng nh?p t?i thi?u $_minChars k� t?.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userName = widget.order.recipientName.isNotEmpty
          ? widget.order.recipientName
          : 'Kh�ch h�ng';
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
      _showMessage('�� g?i d�nh gi�. C�n $remaining s?n ph?m chua d�nh gi�.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (file == null) return;
    setState(() => _selectedImages.add(file));
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(source: source);
    if (file == null) return;
    setState(() => _selectedVideos.add(file));
  }

  Widget _buildSelectedImages() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh đã chọn',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final file = _selectedImages[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      width: 102,
                      height: 102,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImages.removeAt(index);
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectedVideos() {
    if (_selectedVideos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video đã chọn',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedVideos.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Chip(
              label: Text(
                path.basename(file.path),
                overflow: TextOverflow.ellipsis,
              ),
              avatar: const Icon(Icons.videocam, size: 20),
              onDeleted: () => setState(() {
                _selectedVideos.removeAt(index);
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProducts = _pendingItems.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Đánh giá sản phẩm'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange600, AppColors.rose500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _TipBanner(
                  onTap: () => _showMessage('Xem hướng dẫn đánh giá chuẩn.'),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasProducts) ...[
                        if (_pendingItems.length > 1) ...[
                          Text(
                            'Chọn sản phẩm muốn đánh giá',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.gray600),
                          ),
                          const SizedBox(height: 10),
                        ],
                        ..._pendingItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final orderItem = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ProductRow(
                              item: orderItem,
                              isSelected: index == _safeIndex,
                              onTap: () {
                                if (_selectedProductIndex != index) {
                                  setState(() {
                                    _selectedProductIndex = index;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 6),
                      ] else ...[
                        Text(
                          'Đã đánh giá hết sản phẩm trong đơn.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (hasProducts) ...[
                        const Divider(height: 24, color: AppColors.gray200),
                        Text(
                          'Đánh giá sản phẩm',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _StarSelector(
                          rating: _productRating,
                          size: 32,
                          onChanged: (value) =>
                              setState(() => _productRating = value),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Thêm ít nhất 1 hình ảnh/video về sản phẩm',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.gray600),
                        ),
                        const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MediaCard(
                              icon: Icons.photo_camera_outlined,
                              label: 'Hình ảnh',
                              onCameraTap: () =>
                                  _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MediaCard(
                              icon: Icons.videocam_outlined,
                              label: 'Video',
                              onCameraTap: () =>
                                  _pickVideo(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                        const SizedBox(height: 8),
                        _buildSelectedImages(),
                        _buildSelectedVideos(),
                        const SizedBox(height: 4),
                        Text(
                          'Viết đánh giá từ $_minChars ký tự',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.gray600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Hãy chia sẻ nhận xét cho sản phẩm này nhé!',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.gray400),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.gray200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.gray200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.orange600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$_commentLength ký tự',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.gray500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _anonymous,
                          onChanged: (value) => setState(() {
                            _anonymous = value ?? false;
                          }),
                          activeColor: AppColors.orange600,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            'Đánh giá ẩn danh',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasProducts && !_isSubmitting
                      ? _submitReview
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.gray200,
                    disabledForegroundColor: AppColors.gray500,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gray50,
                          ),
                        )
                      : const Text('Gửi đánh giá'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0DA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.orange600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Xem hướng dẫn đánh giá chuẩn',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gray400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.item,
    this.isSelected = false,
    this.onTap,
  });

  final OrderItemSummary item;
  final bool isSelected;
  final VoidCallback? onTap;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.orange600 : AppColors.gray200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.orange600.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.bookImageUrl.isNotEmpty
                  ? Image.network(
                      item.bookImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.gray500,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.gray500,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.bookTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.bookAuthor.isNotEmpty
                        ? item.bookAuthor
                        : 'Tác giả chưa rõ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle,
                    color: AppColors.orange600, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.icon,
    required this.label,
    required this.onCameraTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCameraTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gray200,
            style: BorderStyle.solid,
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gray700),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.gray700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarSelector extends StatelessWidget {
  const _StarSelector({
    required this.rating,
    required this.onChanged,
    required this.size,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final active = starIndex <= rating;
        return GestureDetector(
          onTap: () => onChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              active ? Icons.star : Icons.star_border,
              color: AppColors.orange600,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

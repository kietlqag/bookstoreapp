import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/book.dart';
import '../models/chat_service.dart';
import '../models/voucher.dart';
import '../widgets/price_formatter.dart';
import 'app_colors.dart';

class FloatingChatWidget extends StatefulWidget {
  const FloatingChatWidget({
    super.key,
    required this.baseUrl,
    this.onOpenBook,
  });

  final String baseUrl;
  final ValueChanged<Book>? onOpenBook;

  @override
  State<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<FloatingChatWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final ChatService _chatService;
  late AnimationController _animationController;
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(baseUrl: widget.baseUrl);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Thêm message chào mừng
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content:
            'Xin chào! Tôi là trợ lý AI của cửa hàng sách. Tôi có thể giúp bạn tìm sách, tra cứu đơn hàng, hoặc hỗ trợ các vấn đề khác liên quan đến cửa hàng. Bạn cần hỗ trợ gì?',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Thêm message của user
    final userMessage = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Gửi tất cả messages để AI có context
      final response = await _chatService.sendMessage(_messages);
      print('[Chat Frontend] Received response: message="${response.message}", books=${response.suggestedBooks?.length ?? 0}, vouchers=${response.suggestedVouchers?.length ?? 0}');
      
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        timestamp: DateTime.now(),
        suggestedBooks: response.suggestedBooks,
        suggestedVouchers: response.suggestedVouchers,
      );
      
      print('[Chat Frontend] Created message with books: ${assistantMessage.suggestedBooks?.length ?? 0}');
      
      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: 'Xin lỗi, có lỗi xảy ra: ${e.toString()}',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Vị trí mặc định
    double defaultBottom = 20;
    double defaultRight = 20;
    
    // Sử dụng vị trí từ state nếu đã được kéo
    double bottom = _position.dy == 0 ? defaultBottom : _position.dy;
    double right = _position.dx == 0 ? defaultRight : _position.dx;
    
    // Kích thước vừa phải, không tràn màn hình
    final maxWidth = screenSize.width * 0.85;
    final maxHeight = screenSize.height * 0.7;
    final widgetWidth = _isOpen ? 320.0 : 60.0;
    final widgetHeight = _isOpen ? (screenSize.height * 0.6).clamp(400.0, 550.0) : 60.0;
    
    return Positioned(
      bottom: bottom,
      right: right,
      child: _isOpen
          ? _buildDraggableChatWindow(
              widgetWidth,
              widgetHeight,
              screenSize,
              right,
              bottom,
            )
          : GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                  _animationController.stop();
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  // Với Positioned, bottom tăng = đi lên, bottom giảm = đi xuống
                  // Với delta.dy: dương = kéo xuống, âm = kéo lên
                  // Vậy cần đảo ngược: kéo xuống (delta.dy dương) => bottom giảm
                  double newRight = right - details.delta.dx;
                  double newBottom = bottom - details.delta.dy;
                  final maxRight = screenSize.width - widgetWidth - 20;
                  final maxBottom = screenSize.height - widgetHeight - 20;
                  _position = Offset(
                    newRight.clamp(20.0, maxRight),
                    newBottom.clamp(20.0, maxBottom),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                  _animationController.repeat(reverse: true);
                });
              },
              child: AnimatedContainer(
                duration: _isDragging
                    ? const Duration(milliseconds: 0)
                    : const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: widgetWidth,
                height: widgetHeight,
                child: _buildFloatingButton(),
              ),
            ),
    );
  }

  Widget _buildFloatingButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _isDragging ? 0 : -3 * _animationController.value),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleChat,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange600.withOpacity(0.3),
                      blurRadius: 16 + (4 * _animationController.value),
                      offset: Offset(0, 4 + (2 * _animationController.value)),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom Robot Icon với gradient background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange600,
                            AppColors.rose500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(36, 36),
                          painter: RobotIconPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableChatWindow(
    double width,
    double height,
    Size screenSize,
    double currentRight,
    double currentBottom,
  ) {
    return AnimatedContainer(
      duration: _isDragging
          ? const Duration(milliseconds: 0)
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.85,
        maxHeight: screenSize.height * 0.7,
      ),
      child: _buildChatWindow(currentRight, currentBottom, screenSize, width, height),
    );
  }

  Widget _buildChatWindow(
    double currentRight,
    double currentBottom,
    Size screenSize,
    double widgetWidth,
    double widgetHeight,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header có thể kéo được
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                // Với Positioned, bottom tăng = đi lên, bottom giảm = đi xuống
                // Với delta.dy: dương = kéo xuống, âm = kéo lên
                // Vậy cần đảo ngược: kéo xuống (delta.dy dương) => bottom giảm
                double newRight = currentRight - details.delta.dx;
                double newBottom = currentBottom - details.delta.dy;
                
                final maxRight = screenSize.width - widgetWidth - 20;
                final maxBottom = screenSize.height - widgetHeight - 20;
                
                _position = Offset(
                  newRight.clamp(20.0, maxRight),
                  newBottom.clamp(20.0, maxBottom),
                );
              });
            },
            onPanEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            child: _buildHeader(),
          ),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.orange600,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              size: const Size(24, 24),
              painter: RobotIconPainter(),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleChat,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Bắt đầu cuộc trò chuyện...',
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Loading indicator
          return const Padding(
            padding: EdgeInsets.only(left: 48, top: 8, bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.orange600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final message = _messages[index];
        final isUser = message.role == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.orange600,
                        AppColors.rose500,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomPaint(
                    size: const Size(18, 18),
                    painter: RobotIconPainter(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.orange600
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppColors.gray900,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // Hiển thị sách đề xuất
                    if (!isUser &&
                        message.suggestedBooks != null &&
                        message.suggestedBooks!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...message.suggestedBooks!.map((book) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSuggestedBookCard(book),
                        );
                      }),
                    ],
                    // Hiển thị voucher đề xuất
                    if (!isUser &&
                        message.suggestedVouchers != null &&
                        message.suggestedVouchers!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...message.suggestedVouchers!.map((voucher) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSuggestedVoucherCard(voucher),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.gray600,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppColors.orange600,
                    width: 2,
                  ),
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.orange600,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedVoucherCard(Voucher voucher) {
    String discountText;
    if (voucher.discountType == 'percentage') {
      discountText = 'Giảm ${voucher.discountValue.toStringAsFixed(0)}%';
      if (voucher.maxDiscount != null) {
        discountText += ' (tối đa ${formatPrice(voucher.maxDiscount!)})';
      }
    } else {
      discountText = 'Giảm ${formatPrice(voucher.discountValue)}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange200),
        gradient: LinearGradient(
          colors: [
            AppColors.orange50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Icon voucher
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.orange100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.orange200),
            ),
            child: const Icon(
              Icons.local_offer,
              color: AppColors.orange600,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Thông tin voucher
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  discountText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange600,
                  ),
                ),
                if (voucher.description != null && voucher.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    voucher.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Code: ${voucher.code}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Copy icon
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: voucher.code));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã copy mã: ${voucher.code}'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.orange600,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_outlined,
                color: AppColors.orange600,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedBookCard(Book book) {
    final discountRate = (book.discount / 100).clamp(0.0, 1.0);
    final finalPrice = (book.price * (1 - discountRate)).clamp(0.0, double.infinity);

    return InkWell(
      onTap: widget.onOpenBook != null
          ? () {
              Navigator.of(context).pop(); // Đóng chat
              widget.onOpenBook!(book);
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Row(
          children: [
            // Hình ảnh sách
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              clipBehavior: Clip.antiAlias,
              child: book.cover.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.cover,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.book_outlined,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.book_outlined,
                      color: AppColors.gray400,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 8),
            // Thông tin sách
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.gray600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (book.discount > 0) ...[
                        Flexible(
                          child: Text(
                            formatPrice(book.price),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          formatPrice(finalPrice),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange600,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter cho Robot Icon
class RobotIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;

    // Vẽ đầu robot (hình tròn trắng)
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      paint,
    );

    // Vẽ visor (khu vực mắt màu xanh đậm)
    paint.color = const Color(0xFF1E3A5F); // Dark blue
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size.height * 0.05),
        width: size.width * 0.6,
        height: size.height * 0.25,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(visorRect, paint);

    // Vẽ hai mắt màu xanh sáng
    paint.color = const Color(0xFF00D4FF); // Bright cyan
    final eyeRadius = size.width * 0.08;
    canvas.drawCircle(
      Offset(centerX - size.width * 0.15, centerY - size.height * 0.05),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + size.width * 0.15, centerY - size.height * 0.05),
      eyeRadius,
      paint,
    );

    // Vẽ miệng cười
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.05;
    paint.strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + size.height * 0.1),
        width: size.width * 0.4,
        height: size.height * 0.2,
      ),
      -0.5,
      1.0,
    );
    canvas.drawPath(smilePath, paint);

    // Vẽ antenna ở trên đầu
    paint.style = PaintingStyle.fill;
    paint.color = Colors.black;
    canvas.drawCircle(
      Offset(centerX + size.width * 0.25, centerY - size.height * 0.35),
      size.width * 0.04,
      paint,
    );
    paint.strokeWidth = size.width * 0.03;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX + size.width * 0.25, centerY - size.height * 0.35),
      Offset(centerX + size.width * 0.25, centerY - size.height * 0.45),
      paint,
    );
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX + size.width * 0.25, centerY - size.height * 0.45),
      size.width * 0.03,
      paint,
    );

    // Vẽ chi tiết tay (phần nhô ra ở dưới trái)
    paint.color = const Color(0xFF1E3A5F);
    final armPath = Path();
    armPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX - size.width * 0.35, centerY + size.height * 0.25),
        width: size.width * 0.3,
        height: size.height * 0.3,
      ),
      1.0,
      1.5,
    );
    canvas.drawPath(armPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

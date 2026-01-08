import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/support_service.dart';
import '../models/profile_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';

class OnlineSupportPage extends StatefulWidget {
  const OnlineSupportPage({
    super.key,
    required this.userId,
    required this.token,
  });

  final int userId;
  final String token;

  @override
  State<OnlineSupportPage> createState() => _OnlineSupportPageState();
}

class _OnlineSupportPageState extends State<OnlineSupportPage> {
  late final SupportService _supportService =
      SupportService(baseUrl: _resolveBaseUrl());
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SupportMessage> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;
  Timer? _pollingTimer;
  int? _lastMessageId;
  String? _userAvatar;
  String? _userName;
  // Lưu danh sách ID tin nhắn đã hiển thị thông báo
  final Set<int> _notifiedMessageIds = {};

  // Quick reply messages
  static const List<String> _quickReplies = [
    'Chào shop',
    'Tôi cần hỗ trợ',
    'Kiểm tra đơn hàng',
    'Cảm ơn bạn',
  ];

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    if (Platform.isAndroid) {
      return 'http://192.168.1.155:8080';
    }
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadMessages();
    _startPolling();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileService = ProfileService(baseUrl: _resolveBaseUrl());
      final summary = await profileService.fetchProfileSummary(widget.userId);
      if (mounted) {
        setState(() {
          _userAvatar = summary.avatar;
          _userName = summary.fullName;
        });
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.userId <= 0) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await _supportService.fetchMessages(widget.userId);
      if (!mounted) return;
      
      // Đánh dấu tất cả tin nhắn chưa đọc từ staff là đã đọc (vì user đang ở trong chat)
      final unreadStaffMessages = messages
          .where((msg) => !msg.isFromUser && !msg.isRead)
          .map((msg) => msg.id)
          .toList();
      
      if (unreadStaffMessages.isNotEmpty) {
        try {
          await _supportService.markMessagesAsRead(
            userId: widget.userId,
            messageIds: unreadStaffMessages,
          );
          // Reload messages để có trạng thái isRead mới nhất
          final updatedMessages = await _supportService.fetchMessages(widget.userId);
          if (!mounted) return;
          
          setState(() {
            _messages = updatedMessages;
            _loading = false;
            if (updatedMessages.isNotEmpty) {
              _lastMessageId = updatedMessages.last.id;
            }
          });
          _scrollToBottom();
          return;
        } catch (error) {
          debugPrint('[Chat] Error marking messages as read: $error');
        }
      }
      
      setState(() {
        _messages = messages;
        _loading = false;
        // Lưu ID tin nhắn cuối cùng
        if (messages.isNotEmpty) {
          _lastMessageId = messages.last.id;
        }
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _startPolling() {
    // Polling mỗi 2 giây để check tin nhắn mới
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkNewMessages();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkNewMessages() async {
    if (widget.userId <= 0 || _lastMessageId == null) return;

    try {
      // Load lại tất cả tin nhắn từ ID cuối
      final messages = await _supportService.fetchMessages(widget.userId);
      if (!mounted || messages.isEmpty) return;

      // Tìm tin nhắn mới (sau _lastMessageId)
      final newMessages = messages.where((msg) => msg.id > _lastMessageId!).toList();
      
      if (newMessages.isNotEmpty && mounted) {
        // Tìm tin nhắn mới chưa đọc từ staff để hiển thị thông báo
        final unreadStaffMessages = newMessages
            .where((msg) => !msg.isFromUser && !msg.isRead && !_notifiedMessageIds.contains(msg.id))
            .toList();
        
        // Hiển thị thông báo cho mỗi tin nhắn chưa đọc (chỉ hiện 1 lần)
        for (final msg in unreadStaffMessages) {
          _notifiedMessageIds.add(msg.id);
          _showNewMessageNotification(msg);
        }
        
        // Đánh dấu tin nhắn mới từ staff là đã đọc (vì user đang ở trong chat)
        final newStaffMessages = newMessages
            .where((msg) => !msg.isFromUser && !msg.isRead)
            .map((msg) => msg.id)
            .toList();
        
        if (newStaffMessages.isNotEmpty) {
          try {
            await _supportService.markMessagesAsRead(
              userId: widget.userId,
              messageIds: newStaffMessages,
            );
            // Reload lại messages để có trạng thái isRead mới nhất
            final updatedMessages = await _supportService.fetchMessages(widget.userId);
            if (!mounted) return;
            
            setState(() {
              _messages = updatedMessages;
              _lastMessageId = updatedMessages.last.id;
            });
            _scrollToBottom();
            return;
          } catch (error) {
            debugPrint('[Chat] Error marking new messages as read: $error');
          }
        }
        
        setState(() {
          _messages.addAll(newMessages);
          _lastMessageId = messages.last.id;
        });
        _scrollToBottom();
      }
    } catch (error) {
      // Silent fail để không làm gián đoạn UX
      debugPrint('[Polling] Error checking new messages: $error');
    }
  }

  void _showNewMessageNotification(SupportMessage message) {
    if (!mounted) return;
    
    // Hiển thị thông báo nổi với nội dung tin nhắn
    final messagePreview = message.message.length > 50 
        ? '${message.message.substring(0, 50)}...' 
        : message.message;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tin nhắn mới từ hỗ trợ viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    messagePreview,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.orange600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () {
            _scrollToBottom();
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final newMessages = await _supportService.sendMessage(
        userId: widget.userId,
        message: message,
      );
      
      if (!mounted) return;
      
      _messageController.clear();
      setState(() {
        _messages = newMessages;
        _sending = false;
        if (newMessages.isNotEmpty) {
          _lastMessageId = newMessages.last.id;
        }
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _sending = false;
      });
      _showMessage('Đã xảy ra lỗi. Vui lòng thử lại sau.');
    }
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Hỗ trợ trực tuyến'),
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
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.red500,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.gray700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _error = null;
                                });
                                _loadMessages();
                                _startPolling();
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.support_agent_outlined,
                                    size: 40,
                                    color: AppColors.orange600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Xin chào! 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppColors.gray900,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.gray600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                // Quick reply buttons
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: _quickReplies.map((reply) {
                                      return _QuickReplyButton(
                                        text: reply,
                                        onTap: () {
                                          _messageController.text = reply;
                                          _sendMessage();
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final prevMessage = index > 0 ? _messages[index - 1] : null;
                              final nextMessage = index < _messages.length - 1 ? _messages[index + 1] : null;
                              
                              // Hiển thị avatar nếu tin nhắn đầu tiên hoặc khác người gửi với tin trước
                              final showAvatar = prevMessage == null || 
                                  prevMessage.isFromUser != message.isFromUser;
                              
                              // Chỉ hiển thị thời gian và trạng thái nếu:
                              // 1. Là tin nhắn cuối cùng, HOẶC
                              // 2. Tin nhắn tiếp theo khác người gửi, HOẶC
                              // 3. Tin nhắn tiếp theo cách nhau > 5 phút
                              final showTimeAndStatus = nextMessage == null ||
                                  nextMessage.isFromUser != message.isFromUser ||
                                  nextMessage.createdAt.difference(message.createdAt).inMinutes > 5;
                              
                              return _MessageBubble(
                                message: message.message,
                                isFromUser: message.isFromUser,
                                createdAt: message.createdAt,
                                isRead: message.isRead,
                                showAvatar: showAvatar,
                                showTimeAndStatus: showTimeAndStatus,
                                userAvatar: _userAvatar,
                                userName: _userName ?? 'Bạn',
                              );
                            },
                          ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.gray200),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray400),
                        filled: true,
                        fillColor: AppColors.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: !_sending ? AppColors.orange600 : AppColors.gray400,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: !_sending ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFromUser,
    required this.createdAt,
    required this.isRead,
    this.showAvatar = true,
    this.showTimeAndStatus = true,
    this.userAvatar,
    this.userName = 'Bạn',
  });

  final String message;
  final bool isFromUser;
  final DateTime createdAt;
  final bool isRead;
  final bool showAvatar;
  final bool showTimeAndStatus;
  final String? userAvatar;
  final String userName;


  Widget _buildAvatar() {
    if (!showAvatar) {
      return const SizedBox(width: 36);
    }

    if (isFromUser) {
      // User avatar
      if (userAvatar != null && userAvatar!.isNotEmpty) {
        if (userAvatar!.startsWith('data:image')) {
          try {
            final base64Part = userAvatar!.split(',').last;
            final bytes = base64Decode(base64Part);
            return ClipOval(
              child: Image.memory(
                bytes,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {
            return _buildAvatarFallback();
          }
        } else {
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: userAvatar!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildAvatarFallback(),
              errorWidget: (context, url, error) => _buildAvatarFallback(),
            ),
          );
        }
      }
      return _buildAvatarFallback();
    } else {
      // Staff avatar (mặc định icon support)
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange600, AppColors.rose500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.support_agent,
          size: 20,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildAvatarFallback() {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.orange600,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isFromUser && showAvatar) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      'Hỗ trợ viên',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.gray500,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFromUser 
                        ? AppColors.orange600 
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isFromUser ? 18 : 4),
                      bottomRight: Radius.circular(isFromUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFromUser
                            ? AppColors.orange600.withOpacity(0.2)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromUser ? Colors.white : AppColors.gray900,
                          fontSize: 14,
                          height: 1.4,
                        ),
                  ),
                ),
                // Chỉ hiển thị thời gian và trạng thái ở tin nhắn cuối cùng của nhóm
                if (showTimeAndStatus) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                      left: isFromUser ? 0 : 4,
                      right: isFromUser ? 4 : 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.formatChatTime(createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.gray400,
                                fontSize: 10,
                              ),
                        ),
                        // Hiển thị icon trạng thái đã đọc/chưa đọc cho tin nhắn từ staff
                        if (!isFromUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.access_time,
                            size: 14,
                            color: isRead ? AppColors.blue500 : AppColors.gray400,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  const _QuickReplyButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.orange600.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange600.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.orange600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
        ),
      ),
    );
  }
}

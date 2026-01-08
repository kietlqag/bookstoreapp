class DateFormatter {
  /// Format thời gian tương đối (relative time)
  /// Ví dụ: "Vừa xong", "5 phút trước", "2 giờ trước", "Hôm qua", "3 ngày trước", "15/01/2024 14:30"
  static String formatRelativeTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDateTime(localDate);
    }
  }

  /// Format ngày và giờ đầy đủ: "dd/MM/yyyy HH:mm"
  /// Ví dụ: "15/01/2024 14:30"
  static String formatDateTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Format chỉ ngày: "dd/MM/yyyy"
  /// Ví dụ: "15/01/2024"
  static String formatDate(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    return '$day/$month/$year';
  }

  /// Format ngày và tháng: "dd/MM"
  /// Ví dụ: "15/01"
  static String formatDateShort(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  /// Format cho chat message: hiển thị giờ nếu cùng ngày, ngày tháng nếu khác ngày
  /// Ví dụ: "14:30" hoặc "15/01 14:30" hoặc "Hôm qua 14:30"
  static String formatChatTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    if (difference.inDays == 0) {
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hôm qua $hour:$minute';
    } else {
      return '${formatDateShort(localDate)} $hour:$minute';
    }
  }

  /// Format ngày cho shipping: "dd Tháng MM"
  /// Ví dụ: "15 Tháng 01"
  static String formatShippingDate(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    return '${localDate.day} Tháng ${localDate.month.toString().padLeft(2, '0')}';
  }
}

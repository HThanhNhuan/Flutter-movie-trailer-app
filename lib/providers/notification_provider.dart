import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  int get unreadCount => _unreadCount;

  NotificationProvider() {
    refreshUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    _unreadCount = await _dbHelper.getUnreadNotificationCount();
    notifyListeners();
  }

  Future<void> clear() async {
    _unreadCount = 0;
    // Thực tế, việc clear nên là đánh dấu tất cả đã đọc trong DB,
    // nhưng để đơn giản, chúng ta chỉ reset UI và sẽ cập nhật lại khi mở app lần sau.
    notifyListeners();
  }
}

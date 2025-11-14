import 'package:flutter/material.dart';

// =========================================================================
// WIDGET 6: NotificationItem (Model) and NotificationPage (Stateful Widget)
// =========================================================================

class NotificationItem {
  final String message;
  bool isRead;

  NotificationItem({required this.message, this.isRead = false});
}

class NotificationPage extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final List<NotificationItem>? notifications;

  const NotificationPage({
    super.key,
    required this.onNavigateToHome,
    this.notifications,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notifications ?? [
      NotificationItem(
          message:
          'Gilbert, you placed an order check your order history for full details',
          isRead: false),
      NotificationItem(
          message: 'Gilbert, Thank you for shopping with us we have canceled order #24568',
          isRead: true),
      NotificationItem(
          message:
          'Gilbert, your Order #24568 has been confirmed check your order history for f...',
          isRead: true),
    ];
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNotifications = _notifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: widget.onNavigateToHome,
        ),
      ),
      backgroundColor: Colors.white,
      body: hasNotifications
          ? _buildNotificationList()
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    const double iconSize = 80.0;
    const Color buttonPurple = Color(0xFF9b59b6);

    final Widget animatedBellIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(iconSize / 2),
      ),
      child: const Icon(
        Icons.notifications_active,
        color: Color(0xFFF7C555),
        size: iconSize - 10,
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            animatedBellIcon,
            const SizedBox(height: 30),
            const Text(
              'No Notification yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onNavigateToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Explore Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final bool isUnread = !item.isRead;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: GestureDetector(
            onTap: () => _markAsRead(index),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isUnread ? Colors.grey.shade200 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: isUnread ? Colors.black : Colors.grey.shade600,
                        size: 28,
                      ),
                      if (isUnread)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.circle,
                            color: Colors.red,
                            size: 8,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                        color: isUnread ? Colors.black87 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
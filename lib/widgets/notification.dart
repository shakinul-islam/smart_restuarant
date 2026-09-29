import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBell extends StatelessWidget {
  final String restaurantId;
  final String role; // 'admin', 'kitchen', 'waiter'

  const NotificationBell({
    Key? key,
    required this.restaurantId,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Firestore theke realtime data anar stream
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('target_roles', arrayContains: role) // Role onujayi filter
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.error_outline, color: Colors.red);
        }

        final docs = snapshot.data?.docs ?? [];

        // Unread notification count ber kora
        final unreadCount = docs.where((doc) => doc['is_read'] == false).length;

        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.notifications_active_outlined),
          ),
          onPressed: () => _showNotificationPanel(context, docs),
        );
      },
    );
  }

  // Notification e click korle UI update kora (Mark as read)
  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'is_read': true});
  }

  // Mark all as read function
  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      if (doc['is_read'] == false) {
        batch.update(doc.reference, {'is_read': true});
      }
    }
    await batch.commit();
  }

  // Single Notification Delete (Swipe to delete)
  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // Clear All Notifications
  Future<void> _clearAllNotifications(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Notification List er Popup Dialog
  void _showNotificationPanel(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        // Dialog use kora hoyeche jate width control kora jay ebong overflow na hoy
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width:
                MediaQuery.of(context).size.width *
                0.85, // Width barano hoyeche
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 600,
            ), // Responsive Max Size
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row (Fixed Overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Mark all as read',
                          icon: const Icon(Icons.checklist, color: Colors.blue),
                          onPressed: () {
                            _markAllAsRead(docs);
                          },
                        ),
                        IconButton(
                          tooltip: 'Clear All',
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _clearAllNotifications(docs);
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                // Scrollable List
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final isRead = data['is_read'] ?? true;
                            final timestamp = data['timestamp'] as Timestamp?;

                            // Swipe to Delete Wrap
                            return Dismissible(
                              key: Key(docs[index].id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.redAccent,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                _deleteNotification(docs[index].id);
                              },
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isRead
                                        ? Colors.grey[200]!
                                        : Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                color: isRead
                                    ? Colors.white
                                    : Colors.blue.withOpacity(0.05),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: _getIconColor(
                                      data['title'],
                                    ),
                                    child: Icon(
                                      _getIcon(data['title']),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    data['title'] ?? 'Alert',
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        data['message'] ?? '',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _getTimeAgo(timestamp?.toDate()),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (!isRead) _markAsRead(docs[index].id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI Helper: Title onujayi Icon
  IconData _getIcon(String? title) {
    if (title == null) return Icons.notifications;
    if (title.toLowerCase().contains('order')) return Icons.restaurant_menu;
    if (title.toLowerCase().contains('ready')) return Icons.room_service;
    if (title.toLowerCase().contains('payment')) return Icons.payment;
    return Icons.info_outline;
  }

  // UI Helper: Title onujayi Icon Color
  Color _getIconColor(String? title) {
    if (title == null) return Colors.grey;
    if (title.toLowerCase().contains('order')) return Colors.orange;
    if (title.toLowerCase().contains('ready')) return Colors.green;
    if (title.toLowerCase().contains('payment')) return Colors.blue;
    return Colors.grey;
  }

  // UI Helper: Time formatter
  String _getTimeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

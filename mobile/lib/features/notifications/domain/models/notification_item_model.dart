import 'package:flutter/material.dart';

/// Notification categories supported across Rally (Active Implemented Features Only)
enum NotificationCategory {
  invite,
  rating,
  verified,
  account,
  system,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get tagLabel {
    switch (this) {
      case NotificationCategory.invite:
        return 'INVITE';
      case NotificationCategory.rating:
        return 'RATING';
      case NotificationCategory.verified:
        return 'VERIFIED';
      case NotificationCategory.account:
        return 'ACCOUNT';
      case NotificationCategory.system:
        return 'SYSTEM';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationCategory.invite:
        return 'Match Invitation';
      case NotificationCategory.rating:
        return 'Rating & ELO Update';
      case NotificationCategory.verified:
        return 'Score Verification';
      case NotificationCategory.account:
        return 'Account & Security';
      case NotificationCategory.system:
        return 'System Alert';
    }
  }

  IconData get iconData {
    switch (this) {
      case NotificationCategory.invite:
        return Icons.flash_on_rounded;
      case NotificationCategory.rating:
        return Icons.trending_up_rounded;
      case NotificationCategory.verified:
        return Icons.verified_rounded;
      case NotificationCategory.account:
        return Icons.security_rounded;
      case NotificationCategory.system:
        return Icons.info_outline_rounded;
    }
  }
}

/// Dynamic Notification Item Model
class NotificationItemModel {
  final String id;
  final NotificationCategory category;
  final String title;
  final String subtitle;
  final String dateText;
  final DateTime timestamp;
  bool isUnread;
  final Map<String, dynamic>? payload;

  NotificationItemModel({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.timestamp,
    this.isUnread = true,
    this.payload,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    NotificationCategory cat = NotificationCategory.system;
    final catStr = (json['category'] as String? ?? '').toLowerCase();
    for (final c in NotificationCategory.values) {
      if (c.name == catStr || c.tagLabel.toLowerCase() == catStr) {
        cat = c;
        break;
      }
    }

    return NotificationItemModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: cat,
      title: json['title'] as String? ?? 'Notification',
      subtitle: json['subtitle'] as String? ?? '',
      dateText: json['date_text'] as String? ?? 'Recently',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isUnread: json['is_unread'] as bool? ?? true,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'subtitle': subtitle,
      'date_text': dateText,
      'timestamp': timestamp.toIso8601String(),
      'is_unread': isUnread,
      'payload': payload,
    };
  }
}

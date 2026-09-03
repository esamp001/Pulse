class CourtReviewModel {
  final String id;
  final String courtId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool isLiked;
  final String? comment;
  final DateTime createdAt;

  const CourtReviewModel({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isLiked,
    this.comment,
    required this.createdAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mo' : 'mos'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  factory CourtReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return CourtReviewModel(
      id: json['id']?.toString() ?? '',
      courtId: json['court_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Pulse Player',
      userAvatar: json['user_avatar']?.toString(),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || json['is_liked'] == 'true',
      comment: json['comment']?.toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'court_id': courtId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'is_liked': isLiked,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

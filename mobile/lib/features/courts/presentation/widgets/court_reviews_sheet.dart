import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/court_model.dart';
import '../../models/court_review_model.dart';
import '../../services/court_service.dart';

class CourtReviewsSheet extends StatefulWidget {
  final CourtModel court;
  final bool isDarkMode;
  final ValueChanged<CourtModel>? onCourtUpdated;

  const CourtReviewsSheet({
    super.key,
    required this.court,
    required this.isDarkMode,
    this.onCourtUpdated,
  });

  @override
  State<CourtReviewsSheet> createState() => _CourtReviewsSheetState();
}

class _CourtReviewsSheetState extends State<CourtReviewsSheet> {
  final CourtService _courtService = CourtService();
  final TextEditingController _commentController = TextEditingController();

  late CourtModel _court;
  List<CourtReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool? _selectedVote; // true = Like, false = Dislike

  @override
  void initState() {
    super.initState();
    _court = widget.court;
    _selectedVote = widget.court.userVote;
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final data = await _courtService.fetchCourtReviews(_court.id);
    if (mounted) {
      final loadedReviews = (data['reviews'] as List<CourtReviewModel>?) ?? [];
      final currentUserId = AuthService.currentUser?.id;
      bool? resolvedUserVote = data['userVote'] as bool?;
      if (resolvedUserVote == null && currentUserId != null) {
        final myReview = loadedReviews.cast<CourtReviewModel?>().firstWhere(
          (r) => r?.userId == currentUserId,
          orElse: () => null,
        );
        if (myReview != null) {
          resolvedUserVote = myReview.isLiked;
        }
      }

      setState(() {
        _reviews = loadedReviews;
        if (resolvedUserVote != null) {
          _selectedVote = resolvedUserVote;
        }
        _court = _court.copyWith(
          likesCount: data['likesCount'] as int? ?? _court.likesCount,
          dislikesCount: data['dislikesCount'] as int? ?? _court.dislikesCount,
          userVote: resolvedUserVote ?? _court.userVote,
        );
        _isLoading = false;
      });
      widget.onCourtUpdated?.call(_court);
    }
  }

  Future<void> _handleVote(bool isLiked) async {
    final comment = _commentController.text.trim();
    final previousVote = _selectedVote;

    // Enforce 1 vote per user: if user already cast this exact vote and has no new comment, do not re-vote
    if (previousVote == isLiked && comment.isEmpty) {
      return;
    }

    setState(() {
      _selectedVote = isLiked;
      _isSubmitting = true;
    });

    final result = await _courtService.submitCourtReview(
      courtId: _court.id,
      isLiked: isLiked,
      comment: comment.isNotEmpty ? comment : null,
    );

    if (mounted) {
      if (result != null) {
        _commentController.clear();
        final review = result['review'] as CourtReviewModel?;
        CourtReviewModel? resolvedReview;
        if (review != null) {
          resolvedReview =
              (review.userAvatar == null || review.userAvatar!.isEmpty) &&
                  AuthService.currentUser?.avatarUrl != null
              ? CourtReviewModel(
                  id: review.id,
                  courtId: review.courtId,
                  userId: review.userId,
                  userName:
                      (review.userName == 'Pulse Player' ||
                              review.userName.isEmpty) &&
                          AuthService.currentUser?.name != null
                      ? AuthService.currentUser!.name
                      : review.userName,
                  userAvatar: AuthService.currentUser?.avatarUrl,
                  isLiked: review.isLiked,
                  comment: review.comment,
                  createdAt: review.createdAt,
                )
              : review;
        }

        final serverLikes = result['likesCount'] as int?;
        final serverDislikes = result['dislikesCount'] as int?;

        setState(() {
          if (resolvedReview != null &&
              resolvedReview.comment != null &&
              resolvedReview.comment!.trim().isNotEmpty) {
            _reviews.removeWhere((r) => r.id == resolvedReview!.id);
            _reviews.insert(0, resolvedReview);
          }

          int updatedLikes = serverLikes ?? _court.likesCount;
          int updatedDislikes = serverDislikes ?? _court.dislikesCount;

          if (serverLikes == null) {
            // Calculate 1 vote per user change
            if (previousVote == null) {
              if (isLiked) {
                updatedLikes++;
              } else {
                updatedDislikes++;
              }
            } else if (previousVote != isLiked) {
              if (isLiked) {
                updatedLikes++;
                updatedDislikes = (updatedDislikes - 1).clamp(0, 999999);
              } else {
                updatedDislikes++;
                updatedLikes = (updatedLikes - 1).clamp(0, 999999);
              }
            }
          }

          _court = _court.copyWith(
            likesCount: updatedLikes,
            dislikesCount: updatedDislikes,
            userVote: isLiked,
          );
        });
        widget.onCourtUpdated?.call(_court);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              comment.isNotEmpty
                  ? 'Tip shared to community advice! 💬'
                  : (isLiked
                        ? 'Marked as Recommended 👍'
                        : 'Feedback submitted 👎'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: PulseColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Optimistic fallback enforcing 1 vote per user
        if (comment.isNotEmpty) {
          final localReview = CourtReviewModel(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            courtId: _court.id,
            userId: AuthService.currentUser?.id ?? 'local-user',
            userName: AuthService.currentUser?.name ?? 'You',
            userAvatar: AuthService.currentUser?.avatarUrl,
            isLiked: isLiked,
            comment: comment,
            createdAt: DateTime.now(),
          );
          setState(() {
            _reviews.insert(0, localReview);
          });
        }
        setState(() {
          int updatedLikes = _court.likesCount;
          int updatedDislikes = _court.dislikesCount;
          if (previousVote == null) {
            if (isLiked) {
              updatedLikes++;
            } else {
              updatedDislikes++;
            }
          } else if (previousVote != isLiked) {
            if (isLiked) {
              updatedLikes++;
              updatedDislikes = (updatedDislikes - 1).clamp(0, 999999);
            } else {
              updatedDislikes++;
              updatedLikes = (updatedLikes - 1).clamp(0, 999999);
            }
          }
          _court = _court.copyWith(
            likesCount: updatedLikes,
            dislikesCount: updatedDislikes,
            userVote: isLiked,
          );
        });
        widget.onCourtUpdated?.call(_court);
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              comment.isNotEmpty
                  ? 'Tip shared to community advice! 💬'
                  : (isLiked
                        ? 'Marked as Recommended 👍'
                        : 'Feedback submitted 👎'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: PulseColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: PulseColors.getBackground(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: PulseColors.getTextSecondary(
                  isDark,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player Tips & Reviews',
                      style: TextStyle(
                        color: PulseColors.getTextPrimary(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _court.name,
                      style: TextStyle(
                        color: PulseColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: isDark
                    ? Colors.white
                    : PulseColors.getTextSecondary(isDark),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating Overview Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: PulseColors.getCard(isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _court.recommendationPercent >= 60
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : PulseColors.primary.withValues(alpha: 0.15))
                        : Colors.orangeAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _court.recommendationPercent >= 60
                        ? Icons.thumb_up_rounded
                        : Icons.thumbs_up_down_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white
                        : (_court.recommendationPercent >= 60
                              ? PulseColors.primary
                              : Colors.orangeAccent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _court.totalVotes > 0
                            ? '${_court.recommendationPercent}% Recommended'
                            : 'No Reviews Yet',
                        style: TextStyle(
                          color: PulseColors.getTextPrimary(isDark),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _court.totalVotes > 0
                            ? '${_court.likesCount} players like • ${_court.dislikesCount} dislike'
                            : 'Be the first player to review this venue',
                        style: TextStyle(
                          color: PulseColors.getTextSecondary(isDark),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Like / Dislike Vote Buttons
          Row(
            children: [
              // Like Button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _handleVote(true),
                    icon: Icon(
                      _selectedVote == true
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 15,
                      color: _selectedVote == true
                          ? Colors.white
                          : (isDark ? Colors.white : PulseColors.primary),
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Recommend',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedVote == true
                              ? Colors.white
                              : (isDark ? Colors.white : PulseColors.primary),
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedVote == true
                          ? PulseColors.primary
                          : PulseColors.getCard(isDark),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dislike Button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _handleVote(false),
                    icon: Icon(
                      _selectedVote == false
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_outlined,
                      size: 15,
                      color: _selectedVote == false
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.redAccent),
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Not Recommended',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedVote == false
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.redAccent),
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedVote == false
                          ? Colors.redAccent
                          : PulseColors.getCard(isDark),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment Input Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: PulseColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 1,
                    style: TextStyle(
                      color: PulseColors.getTextPrimary(isDark),
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share advice (lighting, nets, surface...)',
                      hintStyle: TextStyle(
                        color: PulseColors.getTextSecondary(
                          isDark,
                        ).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: IconButton.filled(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_commentController.text.trim().isNotEmpty) {
                            _handleVote(_selectedVote ?? true);
                          }
                        },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reviews Section Title
          Text(
            'Community Advice (${_reviews.length})',
            style: TextStyle(
              color: PulseColors.getTextPrimary(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Reviews List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PulseColors.primary,
                    ),
                  )
                : _reviews.isEmpty
                ? Center(
                    child: Text(
                      'No tips or comments yet.\nBe the first to share advice about this court!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PulseColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final currentUserId = AuthService.currentUser?.id;
                      final isMe =
                          (currentUserId != null &&
                              review.userId == currentUserId) ||
                          review.userId == 'local-user' ||
                          review.userName == 'You';

                      // Retrieve avatar URL (prefer review data, fallback to active session for current user)
                      final avatarUrl =
                          (review.userAvatar != null &&
                              review.userAvatar!.isNotEmpty)
                          ? review.userAvatar
                          : (isMe ? AuthService.currentUser?.avatarUrl : null);

                      // Resolve display name
                      final displayName = isMe
                          ? (AuthService.currentUser?.name != null &&
                                    AuthService.currentUser!.name.isNotEmpty
                                ? AuthService.currentUser!.name
                                : (review.userName.isNotEmpty
                                      ? review.userName
                                      : 'You'))
                          : review.userName;

                      final initials = displayName.trim().isNotEmpty
                          ? displayName
                                .trim()
                                .split(' ')
                                .where((part) => part.isNotEmpty)
                                .map((part) => part[0])
                                .take(2)
                                .join('')
                                .toUpperCase()
                          : 'P';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PulseColors.getCard(isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Actual User Photo / Avatar Circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: PulseColors.getSurface(isDark),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _buildAvatarFallback(
                                            initials,
                                            isDark,
                                          ),
                                    )
                                  : _buildAvatarFallback(initials, isDark),
                            ),
                            const SizedBox(width: 10),

                            // Review Content & Author Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                style: TextStyle(
                                                  color:
                                                      PulseColors.getTextPrimary(
                                                        isDark,
                                                      ),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: PulseColors.primary
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'You',
                                                  style: TextStyle(
                                                    color: PulseColors.primary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        review.timeAgo,
                                        style: TextStyle(
                                          color: PulseColors.getTextSecondary(
                                            isDark,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (review.comment != null &&
                                      review.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      review.comment!,
                                      style: TextStyle(
                                        color: PulseColors.getTextSecondary(
                                          isDark,
                                        ),
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String initials, bool isDark) {
    return Container(
      color: PulseColors.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: PulseColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

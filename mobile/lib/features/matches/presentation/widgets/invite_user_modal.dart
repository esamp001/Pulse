import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';

class InviteUserModal extends StatefulWidget {
  final String role; // 'player2' or 'scorer'
  final String? matchSport;
  final bool isDarkMode;
  final Function(MatchParticipantModel user) onUserSelected;

  const InviteUserModal({
    super.key,
    required this.role,
    this.matchSport,
    required this.isDarkMode,
    required this.onUserSelected,
  });

  @override
  State<InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends State<InviteUserModal> {
  final TextEditingController _searchController = TextEditingController();
  final MatchService _matchService = MatchService();
  List<MatchParticipantModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isUserCompatible(MatchParticipantModel user) {
    if (widget.role != 'player2' || widget.matchSport == null || widget.matchSport!.isEmpty) {
      return true;
    }
    final matchSportKey = widget.matchSport!.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (user.sportRatings != null && user.sportRatings!.isNotEmpty) {
      final userKeys = user.sportRatings!.keys
          .map((k) => k.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim())
          .toSet();
      if (userKeys.contains(matchSportKey)) return true;
    }
    if (user.primarySport != null && user.primarySport!.isNotEmpty) {
      final primaryNorm = user.primarySport!.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      if (primaryNorm == matchSportKey) return true;
    }
    return false;
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _matchService.searchUsers(query);
      if (mounted) {
        setState(() {
          _users = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = widget.role == 'player2' ? 'Invite Opponent (Player 2)' : 'Assign Neutral Scorer';
    final roleSubtitle = widget.role == 'player2'
        ? 'Search for registered players to challenge in this match.'
        : 'Select an impartial referee to record live match scores.';

    final screenWidth = MediaQuery.of(context).size.width;
    final maxModalWidth = screenWidth > 600 ? 600.0 : screenWidth;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxModalWidth),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: PulseColors.getSurface(widget.isDarkMode),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: PulseColors.getBorder(widget.isDarkMode),
              width: 1.5,
            ),
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PulseColors.getTextSecondary(widget.isDarkMode).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PulseColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: PulseColors.accent.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  widget.role == 'player2' ? Icons.person_add_alt_1_rounded : Icons.sports_score_rounded,
                  color: PulseColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.getTextPrimary(widget.isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: PulseColors.getTextSecondary(widget.isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(color: PulseColors.getTextPrimary(widget.isDarkMode)),
            onChanged: (val) => _performSearch(val),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: const TextStyle(color: PulseColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: PulseColors.primary),
              fillColor: PulseColors.getCard(widget.isDarkMode),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: PulseColors.getBorder(widget.isDarkMode)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: PulseColors.getBorder(widget.isDarkMode)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PulseColors.accent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Users List / State
          SizedBox(
            height: 280,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: PulseColors.accent,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: PulseColors.error),
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 40,
                                  color: PulseColors.getTextSecondary(widget.isDarkMode),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No registered users found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: PulseColors.getTextPrimary(widget.isDarkMode),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try searching with a different name or email.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PulseColors.getTextSecondary(widget.isDarkMode),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _users.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: PulseColors.getBorder(widget.isDarkMode),
                            ),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
                                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                          ? Text(
                                              user.initials,
                                              style: const TextStyle(
                                                color: PulseColors.accent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: PulseColors.getTextPrimary(widget.isDarkMode),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: PulseColors.accent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: PulseColors.accent.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  '${user.rating} ELO',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: PulseColors.accent,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  user.email,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: PulseColors.getTextSecondary(widget.isDarkMode),
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
                                     const SizedBox(width: 10),
                                     Builder(
                                       builder: (context) {
                                         final isCompatible = _isUserCompatible(user);
                                         return ElevatedButton(
                                           onPressed: isCompatible
                                               ? () => widget.onUserSelected(user)
                                               : () {
                                                   final sportLabel = widget.matchSport == 'table_tennis'
                                                       ? 'Table Tennis'
                                                       : (widget.matchSport != null && widget.matchSport!.isNotEmpty
                                                           ? '${widget.matchSport![0].toUpperCase()}${widget.matchSport!.substring(1)}'
                                                           : 'this sport');
                                                   PulseToast.show(
                                                     context,
                                                     'Cannot invite ${user.name}: Player has not configured $sportLabel in sport preferences.',
                                                     isError: true,
                                                   );
                                                 },
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: isCompatible
                                                 ? PulseColors.primary
                                                 : PulseColors.getCard(widget.isDarkMode),
                                             foregroundColor: isCompatible
                                                 ? Colors.white
                                                 : PulseColors.getTextSecondary(widget.isDarkMode),
                                             elevation: 0, // STRICT NO DROP SHADOW
                                             shadowColor: Colors.transparent,
                                             minimumSize: const Size(0, 36),
                                             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                             shape: RoundedRectangleBorder(
                                               borderRadius: BorderRadius.circular(10),
                                               side: BorderSide(
                                                 color: isCompatible
                                                     ? PulseColors.primary
                                                     : PulseColors.getBorder(widget.isDarkMode),
                                               ),
                                             ),
                                           ),
                                           child: Text(
                                             isCompatible ? 'Invite' : 'No Sport',
                                             style: TextStyle(
                                               fontSize: 12,
                                               fontWeight: FontWeight.bold,
                                               color: isCompatible
                                                   ? Colors.white
                                                   : PulseColors.getTextSecondary(widget.isDarkMode),
                                             ),
                                           ),
                                         );
                                       },
                                     ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

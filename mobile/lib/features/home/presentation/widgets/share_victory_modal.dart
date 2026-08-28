import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_logo.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';

/// Modal Component to Preview and Flex a Player's ELO Rating Card to Facebook & Socials
class ShareVictoryModal extends StatefulWidget {
  final String userName;
  final int currentElo;
  final String sportName;
  final int winStreak;
  final bool isDarkMode;

  const ShareVictoryModal({
    super.key,
    required this.userName,
    required this.currentElo,
    this.sportName = 'Pickleball',
    this.winStreak = 3,
    required this.isDarkMode,
  });

  static Future<void> show(
    BuildContext context, {
    required String userName,
    required int currentElo,
    String sportName = 'Pickleball',
    int winStreak = 3,
    required bool isDarkMode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareVictoryModal(
        userName: userName,
        currentElo: currentElo,
        sportName: sportName,
        winStreak: winStreak,
        isDarkMode: isDarkMode,
      ),
    );
  }

  @override
  State<ShareVictoryModal> createState() => _ShareVictoryModalState();
}

class _ShareVictoryModalState extends State<ShareVictoryModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareToSocials() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    // Capture sharePositionOrigin before async gaps to avoid use_build_context_synchronously
    final box = context.findRenderObject() as RenderBox?;
    final Rect? sharePositionOrigin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      // 1. Brief post-frame delay to ensure Flutter has painted the RepaintBoundary
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      final String shareText =
          'Flexing my ELO rating on Rally! ${widget.currentElo} ELO #RallySports #FlexYourELO #${widget.sportName}';

      if (boundary != null) {
        if (boundary.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 150));
        }

        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final String filePath ='${tempDir.path}/rally_elo_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = await File(filePath).create();
          await file.writeAsBytes(pngBytes);

          if (!mounted) return;

          final result = await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: shareText,
              subject: 'Rally Player ELO Rating Card',
              sharePositionOrigin: sharePositionOrigin,
            ),
          );

          if (mounted && result.status == ShareResultStatus.success) {
            PulseToast.show(context, 'Shared successfully!');
          }
          return;
        }
      }

      // Fallback: If boundary capture is unavailable, trigger text share
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Rally Player ELO Rating Card',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (err) {
      debugPrint('[ShareVictoryModal Error]: $err');
      if (mounted) {
        try {
          await SharePlus.instance.share(
            ShareParams(
              text:
                  '⚡ Flexing my ELO rating on Rally! ${widget.currentElo} ELO 🚀 #RallySports #FlexYourELO #${widget.sportName}',
              subject: 'Rally Player ELO Rating Card',
              sharePositionOrigin: sharePositionOrigin,
            ),
          );
        } catch (fallbackErr) {
          debugPrint('[ShareVictoryModal Fallback Error]: $fallbackErr');
          if (mounted) {
            PulseToast.show(context, 'Failed to share card. Please try again.');
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode || (themeModeNotifier.value == ThemeMode.dark ||Theme.of(context).brightness == Brightness.dark);

    final bgSurface = PulseColors.getSurface(isDark);
    final cardBg = isDark ? const Color(0xFF141C1D) : const Color(0xFFF8FAFC);
    final textPrimary = PulseColors.getTextPrimary(isDark);
    final textSecondary = PulseColors.getTextSecondary(isDark);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Drag Handle Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Flex Your ELO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Preview Area (Scrollable to prevent 280x520 pixel overflow)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // High-DPI RepaintBoundary Card Frame
                      RepaintBoundary(
                        key: _cardKey,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Brand Text Logo Header
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: PulseLogo(size: 42),
                              ),
                              const SizedBox(height: 18),

                              // Big ELO Rating Header Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F1718), Color(0xFF1C2D2F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${widget.currentElo} ELO',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF4ADE80),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'COMPETITIVE TIER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Player Name & Sport Summary
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.sportName} Player',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ELO Rating Stats Grid (Win Rate & Win Streak)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      label: 'WIN RATE',
                                      value: '68%',
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatItem(
                                      label: 'WIN STREAK',
                                      value: '${widget.winStreak} WINS',
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Verified Tagline
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        size: 14, color: PulseColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified on Rally App • rally.app/verify',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              ElevatedButton(
                onPressed: _isSharing ? null : _shareToSocials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2), // Official Facebook / Social Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSharing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Share to Facebook & Socials',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: PulseColors.getTextSecondary(isDark),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: PulseColors.getTextPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

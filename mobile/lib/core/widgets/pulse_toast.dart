import 'package:flutter/material.dart';

/// Reusable Global Toast Helper that displays top banner notifications smoothly at the top of the header without any SnackBar assertions.
class PulseToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isError
        ? const Color(0xFFD32F2F)
        : (isDark ? const Color(0xFF141E20) : const Color(0xFF1E2E31));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;

        return _TopToastWidget(
          topPadding: topPadding,
          message: message,
          bgColor: bgColor,
          duration: duration,
          onDismiss: () {
            if (_currentOverlay == entry) {
              entry.remove();
              _currentOverlay = null;
            }
          },
        );
      },
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message, isError: false);

  static void showError(BuildContext context, String message) =>
      show(context, message, isError: true);

  static void showInfo(BuildContext context, String message) =>
      show(context, message, isError: false);
}

class _TopToastWidget extends StatefulWidget {
  final double topPadding;
  final String message;
  final Color bgColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.topPadding,
    required this.message,
    required this.bgColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  widget.topPadding > 0 ? widget.topPadding + 10 : 16,
                  16,
                  14,
                ),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

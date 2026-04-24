import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a border "scan" wave, then does a tiny pulse.
class SuccessPulse extends StatefulWidget {
  const SuccessPulse({
    super.key,
    required this.trigger,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.highlightColor = const Color(0xFFFF7A00),
  });

  /// When this changes from false -> true, the animation plays once.
  final bool trigger;
  final Widget child;
  final BorderRadius borderRadius;
  final Color highlightColor;

  @override
  State<SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<SuccessPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _wave;
  late final Animation<double> _pulseT;

  bool _prevTrigger = false;

  @override
  void initState() {
    super.initState();
    _prevTrigger = widget.trigger;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 0..1: border wave progress
    _wave = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.88, curve: Curves.easeInOutCubic),
      ),
    );

    // 0..1: tiny end pulse
    _pulseT = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SuccessPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPlay = !_prevTrigger && widget.trigger;
    _prevTrigger = widget.trigger;
    if (shouldPlay) {
      _fireHaptic();
      _c.forward(from: 0);
    }
  }

  Future<void> _fireHaptic() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // More reliable across Android devices than lightImpact alone.
        await HapticFeedback.selectionClick();
        // Fallback for devices where selectionClick is very subtle.
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {
        // ignore
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final wave = _wave.value;
        final pt = _pulseT.value;
        if (!_c.isAnimating && wave == 0 && pt == 0) {
          return child!;
        }

        // Tiny single pulse at the very end.
        // 0..1..0 bell curve using sine.
        final pulse = math.sin(pt * math.pi).clamp(0.0, 1.0);
        final scale = 1.0 + 0.008 * pulse;

        // Border wave alpha: clearly visible.
        final waveBell = (1.0 - (2 * (wave - 0.5).abs())).clamp(0.0, 1.0);
        final waveAlpha = (0.85 * waveBell).clamp(0.0, 0.85);

        return Transform.scale(
          scale: scale,
          child: Stack(
            children: [
              child!,
              if (waveAlpha > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: widget.borderRadius,
                      child: CustomPaint(
                        painter: _BorderWavePainter(
                          t: wave,
                          color: widget.highlightColor,
                          alpha: waveAlpha,
                          borderRadius: widget.borderRadius,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BorderWavePainter extends CustomPainter {
  _BorderWavePainter({
    required this.t,
    required this.color,
    required this.alpha,
    required this.borderRadius,
  });

  final double t; // 0..1 along perimeter
  final Color color;
  final double alpha;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw slightly inset so the clip doesn't cut the stroke.
    final rrect = borderRadius
        .toRRect(Offset.zero & size)
        .deflate(2.0);
    final path = Path()..addRRect(rrect);

    final it = path.computeMetrics().iterator;
    if (!it.moveNext()) return;
    final pm = it.current;

    final total = pm.length;
    final center = (t.clamp(0.0, 1.0) * total);
    final span = math.max(54.0, total * 0.18); // longer glowing segment
    final start = center - span / 2;
    final end = center + span / 2;

    Path segment;
    if (start >= 0 && end <= total) {
      segment = pm.extractPath(start, end);
    } else {
      // wrap around
      final s = (start % total + total) % total;
      final e = (end % total + total) % total;
      segment = Path();
      if (s < e) {
        segment.addPath(pm.extractPath(s, e), Offset.zero);
      } else {
        segment.addPath(pm.extractPath(s, total), Offset.zero);
        segment.addPath(pm.extractPath(0, e), Offset.zero);
      }
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(alpha);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity((alpha * 0.35).clamp(0.0, 0.35))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final hotCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity((alpha * 0.45).clamp(0.0, 0.45));

    canvas.drawPath(segment, glow);
    canvas.drawPath(segment, stroke);
    canvas.drawPath(segment, hotCore);
  }

  @override
  bool shouldRepaint(covariant _BorderWavePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.alpha != alpha ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}


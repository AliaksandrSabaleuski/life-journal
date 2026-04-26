import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/app_icons.dart';
import '../ui/responsive.dart';
import '../ui/card_typography.dart';
import 'success_pulse.dart';

class ActiveHabitCard extends StatefulWidget {
  const ActiveHabitCard({
    super.key,
    this.title = 'Бегать',
    this.unit = 'минут',
    this.goalMinutes = 15,
    this.accent = const Color(0xFFFF7A00),
    this.initialSeconds = 0,
    this.externalRunning,
    this.onToggleRunning,
    this.isCompleted = false,
    this.customColor,
    this.readOnly = false,
    this.onSave,
    /// Тап по заголовку/прогрессу (не по кнопкам таймера) — открыть редактор.
    this.onOpenEdit,
  });

  final String title;
  final String unit;
  final int goalMinutes;
  final Color accent;
  final int initialSeconds;
  /// Если задано — состояние "запущен/на паузе" контролируется снаружи.
  final bool? externalRunning;
  /// Тоггл состояния таймера, когда управление внешнее.
  final VoidCallback? onToggleRunning;
  final bool isCompleted;
  /// Если задан и не равен 0x00000000 — тонирует фон карточки.
  final Color? customColor;
  /// Если true — отключает интерактивность (play/pause/stop).
  final bool readOnly;
  final ValueChanged<Duration>? onSave;
  final VoidCallback? onOpenEdit;

  @override
  State<ActiveHabitCard> createState() => _ActiveHabitCardState();
}

class _ActiveHabitCardState extends State<ActiveHabitCard>
    with WidgetsBindingObserver {
  static const _maxSeconds = 24 * 60 * 60;

  bool isRunning = false;
  Duration elapsed = Duration.zero;
  Timer? timer;

  bool _wasRunningBeforePause = false;

  Color _tint(Color base, Color tint) {
    final opaque = Color(tint.value | 0xFF000000);
    return Color.lerp(base, opaque, 0.18)!;
  }

  @override
  void initState() {
    super.initState();
    elapsed = Duration(seconds: widget.initialSeconds.clamp(0, _maxSeconds));
    // Если таймер управляется снаружи — карточка не должна жить своим ticker'ом.
    if (widget.externalRunning == null) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didUpdateWidget(covariant ActiveHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final externallyControlled = widget.externalRunning != null;
    if ((externallyControlled || !isRunning) &&
        oldWidget.initialSeconds != widget.initialSeconds) {
      elapsed = Duration(
        seconds: widget.initialSeconds.clamp(0, _maxSeconds),
      );
    }
  }

  void _saveProgress() {
    widget.onSave?.call(elapsed);
  }

  void _startTicking() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final next = elapsed + const Duration(seconds: 1);
        elapsed = next.inSeconds > _maxSeconds
            ? const Duration(seconds: _maxSeconds)
            : next;
      });
    });
  }

  void _toggleTimer() {
    if (widget.externalRunning != null) {
      widget.onToggleRunning?.call();
      return;
    }
    if (isRunning) {
      timer?.cancel();
      timer = null;
      setState(() => isRunning = false);
      _saveProgress();
      return;
    }

    _startTicking();
    setState(() => isRunning = true);
  }

  void _stopTimer() {
    timer?.cancel();
    timer = null;
    _saveProgress();
    setState(() {
      isRunning = false;
      elapsed = Duration.zero;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.externalRunning != null) return;
    // Сохраняем прогресс при сворачивании/уходе в фон и при выгрузке.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (elapsed > Duration.zero) {
        _saveProgress();
      }
      _wasRunningBeforePause = isRunning;
      timer?.cancel();
      timer = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_wasRunningBeforePause && isRunning) {
        _startTicking();
      }
      _wasRunningBeforePause = false;
    }
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _timerLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Transform.translate(
        offset: const Offset(0, 4),
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: HabitAppIcon(size: 134.4),
        ),
      ),
    );
  }

  Widget _buildTimerMiddle(double progress, int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CardTypography.title(context),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatTime(elapsed)} / ${widget.goalMinutes.toString().padLeft(2, '0')} ${widget.unit}',
          style: CardTypography.secondary(context),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE9D9CC),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(
                                Colors.white,
                                widget.accent,
                                0.35,
                              )!,
                              widget.accent,
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: CardTypography.percent(context),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (widget.externalRunning == null) {
      WidgetsBinding.instance.removeObserver(this);
    }
    if (elapsed > Duration.zero) {
      _saveProgress();
    }
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.externalRunning ?? isRunning;
    final goal = Duration(minutes: widget.goalMinutes <= 0 ? 1 : widget.goalMinutes);
    final progress = (elapsed.inSeconds / goal.inSeconds).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final cardBg = widget.isCompleted
        ? const Color(0xFFEDE6DE) // чуть темнее, чем базовый
        : const Color(0xFFF3EFE9);
    final effectiveBg = (widget.customColor != null && widget.customColor!.value != 0)
        ? _tint(cardBg, widget.customColor!)
        : cardBg;
    final contentOpacity = widget.isCompleted ? 0.78 : 1.0;

    const borderRadius = BorderRadius.all(Radius.circular(16));

    return SuccessPulse(
      trigger: widget.isCompleted,
      borderRadius: borderRadius,
      highlightColor: widget.accent,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppResponsive.gap(context, base: 4),
          horizontal: 14,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, base: 16),
          vertical: AppResponsive.gap(context, base: 8),
        ),
        constraints:
            BoxConstraints(minHeight: AppResponsive.minCardHeight(context)),
        decoration: BoxDecoration(
          // В точности как подложки дней в календаре.
          color: effectiveBg,
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Opacity(
          opacity: contentOpacity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Expanded(
            child: widget.onOpenEdit == null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _timerLeadingIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimerMiddle(progress, percent),
                      ),
                    ],
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onOpenEdit,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _timerLeadingIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimerMiddle(progress, percent),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: InkResponse(
                        onTap: widget.readOnly ? null : _toggleTimer,
                        radius: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8D2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            running ? Icons.pause : Icons.play_arrow,
                            color: widget.accent,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    // Кнопку "сброс" убрали: случайно нажимается и мешает UX.
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
        ),
      ),
    );
  }
}


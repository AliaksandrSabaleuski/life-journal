import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/stats_motivation_phrases.dart';
import '../../../../core/widgets/category_pill.dart';
import '../../../../core/ui/app_icons.dart';
import '../../../../core/ui/responsive.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/logic/habit_streak.dart';
import '../../../../core/repositories/habit_logs_repository.dart';
import '../../../../core/repositories/habits_repository.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../subscription/presentation/subscription_screen.dart';
import 'habit_detail_stats_screen.dart';
import 'stats_habit_colors.dart';
import '../../shell/shell_content_insets.dart';

enum StatsPeriod { week, month, year }

/// Высота [StatsPeriodTabBar] в AppBar (с нижним отступом).
const double kStatsPeriodAppBarHeight = 52;

/// Вкладки Week / Month / Year — часть хрома, не скролла.
class StatsPeriodTabBar extends StatelessWidget {
  const StatsPeriodTabBar({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    Widget pill(String label, StatsPeriod value) {
      return Expanded(
        child: CategoryPill(
          text: label,
          selected: period == value,
          accent: accent,
          expandWidth: true,
          onTap: () => onChanged(value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          pill(l.statsPeriodWeek, StatsPeriod.week),
          const SizedBox(width: 8),
          pill(l.statsPeriodMonth, StatsPeriod.month),
          const SizedBox(width: 8),
          pill(l.statsPeriodYear, StatsPeriod.year),
        ],
      ),
    );
  }
}

/// Как у карточек на главной (bool/timer/counter) — только оболочка.
BoxDecoration _habitCardShellDecoration() {
  return BoxDecoration(
    color: const Color(0xFFF3EFE9),
    borderRadius: BorderRadius.circular(16),
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
  );
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.habitsRepository,
    required this.logsRepository,
    required this.motivationNonce,
    required this.period,
  });

  final HabitsRepository habitsRepository;
  final HabitLogsRepository logsRepository;

  /// Увеличивается при каждом переходе на вкладку «Статистика» — новая фраза.
  final int motivationNonce;

  final StatsPeriod period;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  static const Color _coffeeDark = Color(0xFF4A3728);
  static const Color _accentOrange = Color(0xFFB5651D);

  static const _assetCheckMark = 'assets/icons/CheckMark.png';
  static const _assetStreakIcon = 'assets/icons/Streakicon.png';
  /// Логический размер PNG в метриках статистики (84×1.3×0.9).
  static const double _statsMetricIconSize = 98.28;

  static const double _habitStatSwatchSize = 18.2;
  static const double _habitStatCountColWidth = 64;
  static const double _habitStatStreakColWidth = 72;

  String _motivationPhrase = '';

  VoidCallback? _premiumListener;

  @override
  void initState() {
    super.initState();
    _premiumListener = () {
      if (mounted) setState(() {});
    };
    SubscriptionService.isPremiumNotifier.addListener(_premiumListener!);
    _load();
  }

  @override
  void dispose() {
    if (_premiumListener != null) {
      SubscriptionService.isPremiumNotifier.removeListener(_premiumListener!);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Первая подпись до первого кадра (вкл. hot restart на вкладке статистики).
    if (_motivationPhrase.isEmpty) {
      _motivationPhrase =
          StatsMotivationPhrases.pick(Localizations.localeOf(context));
    }
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _load();
    }
    if (oldWidget.motivationNonce != widget.motivationNonce) {
      setState(() {
        _motivationPhrase =
            StatsMotivationPhrases.pick(Localizations.localeOf(context));
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await widget.habitsRepository.getHabits();
    if (!mounted) return;
    final range = _currentRange();
    final logs = <HabitLog>[];
    for (final h in habits) {
      final hLogs = await widget.logsRepository.getLogsForHabitInRange(
        h.id,
        range.$1,
        range.$2,
      );
      logs.addAll(hLogs);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _logs = logs;
      _loading = false;
    });
  }

  (DateTime, DateTime) _currentRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (widget.period) {
      case StatsPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 6)));
      case StatsPeriod.month:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case StatsPeriod.year:
        final start = DateTime(today.year, 1, 1);
        final end = DateTime(today.year, 12, 31);
        return (start, end);
    }
  }

  List<Habit> _activeHabits() {
    return _habits.where((h) => h.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final range = _currentRange();
    final filtered = _activeHabits();

    HabitStats computeHabitStats(Habit h) {
      final habitLogs = _logs.where((log) => log.habitId == h.id).toList();
      final rangeStart = DateTime(range.$1.year, range.$1.month, range.$1.day);
      final rangeEnd = DateTime(range.$2.year, range.$2.month, range.$2.day);
      final totalDays = _countPlannedDays(h, range.$1, range.$2);
      final completedDays =
          habitLogs.where((log) => log.isCompleted == true).length;
      final percent = totalDays > 0
          ? (completedDays / totalDays * 100).clamp(0, 100).toDouble()
          : null;
      return HabitStats(
        habit: h,
        totalPlannedDays: totalDays,
        completedDays: completedDays,
        percent: percent,
        longestStreakInPeriod:
            HabitStreak.longestInRange(h, habitLogs, rangeStart, rangeEnd),
      );
    }

    final habitStats = filtered.map(computeHabitStats).toList()
      ..sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));

    final withPlan = habitStats.where((s) => s.totalPlannedDays > 0).toList();
    final totalGoalsDone =
        withPlan.fold<int>(0, (sum, s) => sum + s.completedDays);
    final bestStreak = withPlan.isEmpty
        ? 0
        : withPlan.map((s) => s.longestStreakInPeriod).reduce(math.max);

    final overallPercent = withPlan.isEmpty
        ? 0.0
        : withPlan
                .map((s) => s.percent ?? 0)
                .fold<double>(0, (a, b) => a + b) /
            withPlan.length;

    final statsColorById =
        statsDefaultColorByHabitId(withPlan.map((s) => s.habit));
    final ringSegments = withPlan
        .map(
          (s) => _StatsRingSegmentData(
            color: statsHabitDisplayColor(s.habit, statsColorById),
            completedDays: s.completedDays,
          ),
        )
        .toList();

    final scrollBottomPad = ShellContentInsets.bottom(context) + 40;
    final topUnderChrome =
        ShellContentInsets.top(context) + kStatsPeriodAppBarHeight + 8;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.sidePadding(context),
        topUnderChrome,
        AppResponsive.sidePadding(context),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: EdgeInsets.fromLTRB(0, 8, 0, scrollBottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopMetrics(context, l, totalGoalsDone, bestStreak),
                  const SizedBox(height: 8),
                  Center(
                    child: _StatsProgressRing(
                      percent: overallPercent,
                      segments: ringSegments,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _motivationPhrase,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _accentOrange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (withPlan.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            l.statsEmptyTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.statsEmptyBody,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _habitStatsTableHeader(context, l),
                    ...withPlan.map(
                      (s) => _habitRow(
                        context,
                        l,
                        s,
                        range,
                        statsColorById,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    l.statsMotivationFooter,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _coffeeDark.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (SubscriptionService.isPremium) {
      return body;
    }

    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.94),
              elevation: 3,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => SubscriptionScreen.show(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.subscriptionBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: _coffeeDark.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => SubscriptionScreen.show(context),
                        child: Text(l.subscriptionTitle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMetrics(
    BuildContext context,
    AppLocalizations l,
    int totalGoalsDone,
    int bestStreak,
  ) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _coffeeDark.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
        );
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _coffeeDark,
          fontWeight: FontWeight.w800,
        );
    final gap = AppResponsive.gap(context, base: 4);
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsMetricCard(
            icon: HabitCardLeadingSlot(
              child: Image.asset(
                _assetCheckMark,
                width: _statsMetricIconSize,
                height: _statsMetricIconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
            label: l.statsTotalCompletedLabel,
            value: l.statsGoalsCount(totalGoalsDone),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          SizedBox(height: gap),
          _StatsMetricCard(
            icon: HabitCardLeadingSlot(
              child: Image.asset(
                _assetStreakIcon,
                width: _statsMetricIconSize,
                height: _statsMetricIconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
            label: l.statsBestStreakLabel,
            value: l.statsStreakDays(bestStreak),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ],
      ),
    );
  }

  Widget _habitStatsTableHeader(BuildContext context, AppLocalizations l) {
    final hPad = AppResponsive.gap(context, base: 16);
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _coffeeDark.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: _habitStatSwatchSize + 12),
          Expanded(
            child: Text(l.statsHabitTableHabit, style: headerStyle),
          ),
          SizedBox(
            width: _habitStatCountColWidth,
            child: Text(
              l.statsHabitTableCount,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: _habitStatStreakColWidth,
            child: Text(
              l.statsHabitTableStreak,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitRow(
    BuildContext context,
    AppLocalizations l,
    HabitStats s,
    (DateTime, DateTime) range,
    Map<String, Color> statsColorById,
  ) {
    final streakLabel = s.longestStreakInPeriod >= 7
        ? '🔥'
        : l.statsStreakDays(s.longestStreakInPeriod);
    final rowStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _coffeeDark,
          height: 1.35,
        );
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppResponsive.gap(context, base: 4)),
      decoration: _habitCardShellDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final logs = _logs.where((log) => log.habitId == s.habit.id).toList();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HabitDetailStatsScreen(
                  habit: s.habit,
                  logs: logs,
                  from: range.$1,
                  to: range.$2,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.gap(context, base: 16),
              vertical: AppResponsive.gap(context, base: 8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _habitStatSwatchSize,
                  height: _habitStatSwatchSize,
                  decoration: BoxDecoration(
                    color: statsHabitDisplayColor(s.habit, statsColorById),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.habit.name,
                    style: rowStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: _habitStatCountColWidth,
                  child: Text(
                    '${s.completedDays}/${s.totalPlannedDays}',
                    style: rowStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                SizedBox(
                  width: _habitStatStreakColWidth,
                  child: Text(
                    streakLabel,
                    style: rowStyle,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _countPlannedDays(Habit habit, DateTime start, DateTime end) {
    var count = 0;
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      if (habit.forDate(d).isScheduledForDate(d)) {
        count++;
      }
      d = d.add(const Duration(days: 1));
    }
    return count;
  }
}

class _StatsMetricCard extends StatelessWidget {
  const _StatsMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final Widget icon;
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  /// Ширина слота иконки ([HabitCardLeadingSlot]) + зазор до текста — зеркалим справа для центра текста в плашке.
  static const double _leadingWidth = 48 + 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.gap(context, base: 16),
        vertical: AppResponsive.gap(context, base: 8),
      ),
      decoration: _habitCardShellDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: _leadingWidth),
        ],
      ),
    );
  }
}

class HabitStats {
  HabitStats({
    required this.habit,
    required this.totalPlannedDays,
    required this.completedDays,
    required this.percent,
    required this.longestStreakInPeriod,
  });

  final Habit habit;
  final int totalPlannedDays;
  final int completedDays;
  final double? percent;
  /// Самая длинная серия успехов внутри выбранного периода (неделя / месяц / год).
  final int longestStreakInPeriod;
}

class _StatsRingSegmentData {
  const _StatsRingSegmentData({
    required this.color,
    required this.completedDays,
  });

  final Color color;
  final int completedDays;
}

/// Кольцо прогресса: фон + цветные дуги по весу [completedDays]; в центре — иконка и средний %.
class _StatsProgressRing extends StatelessWidget {
  const _StatsProgressRing({
    required this.percent,
    required this.segments,
  });

  static const _assetPlantIcon = 'assets/icons/planticon.png';

  final double percent;
  final List<_StatsRingSegmentData> segments;

  @override
  Widget build(BuildContext context) {
    const ringSize = 220.0;
    final iconSize = 256.0 * 1.1;
    final ringInset = (iconSize - ringSize) / 2;
    final p = (percent.isNaN ? 0.0 : percent).clamp(0.0, 100.0);
    final progress = p / 100.0;
    // Высота больше [iconSize]: иконка со сдвигом и антиалиасинг рисуются ниже бокса —
    // иначе SingleChildScrollView обрезает низ по линии вьюпорта (над bottom bar).
    final h = iconSize + 48;
    return SizedBox(
      width: iconSize,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: ringInset,
            top: ringInset,
            width: ringSize,
            height: ringSize,
            child: CustomPaint(
              size: const Size(ringSize, ringSize),
              painter: _StatsRingPainter(
                progress: progress,
                segments: segments,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: iconSize,
            height: iconSize,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 6),
                child: Image.asset(
                  _assetPlantIcon,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          Positioned(
            left: ringInset,
            top: ringInset,
            width: ringSize,
            height: ringSize,
            child: Align(
              alignment: const Alignment(0, 0.44),
              child: Text(
                '${p.round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRingPainter extends CustomPainter {
  _StatsRingPainter({
    required this.progress,
    required this.segments,
  });

  final double progress;
  final List<_StatsRingSegmentData> segments;

  static const _track = Color(0xFFE8DCCB);
  static const _stroke = 12.0;

  static List<double> _normalizedWeights(List<_StatsRingSegmentData> segments) {
    final sum = segments.fold<int>(0, (a, s) => a + s.completedDays);
    if (sum > 0) {
      return segments.map((s) => s.completedDays / sum).toList();
    }
    final n = segments.length;
    if (n == 0) return [];
    return List.filled(n, 1.0 / n);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = _track
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    final t = progress.clamp(0.0, 1.0);
    if (t <= 0 || segments.isEmpty) return;

    final weights = _normalizedWeights(segments);
    final totalSweep = 2 * math.pi * t;
    var nonZeroCount = 0;
    for (var i = 0; i < segments.length; i++) {
      if (totalSweep * weights[i] > 1e-9) nonZeroCount++;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -math.pi / 2;

    for (var i = 0; i < segments.length; i++) {
      final sweep = totalSweep * weights[i];
      if (sweep <= 1e-9) continue;

      final progressPaint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = nonZeroCount == 1 ? StrokeCap.round : StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweep, false, progressPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatsRingPainter oldDelegate) {
    if (oldDelegate.progress != progress ||
        oldDelegate.segments.length != segments.length) {
      return true;
    }
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].color != segments[i].color ||
          oldDelegate.segments[i].completedDays != segments[i].completedDays) {
        return true;
      }
    }
    return false;
  }
}

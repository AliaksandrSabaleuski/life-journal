import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/repositories/habits_repository.dart';
import '../../../../l10n/app_localizations.dart';
import 'main_menu_content.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../assistant/presentation/assistant_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// Оболочка приложения: AppBar (настройки, поиск, подписка) + контент по вкладке + нижняя навигация.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<Habit> _habits = [];
  final HabitsRepository _habitsRepository = HabitsRepository();
  bool _habitsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final list = await _habitsRepository.getHabits();
    if (mounted) {
      setState(() {
        _habits = list;
        _habitsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Все вкладки в дереве один раз — переключение без пересоздания контента.
    final body = IndexedStack(
      index: _currentIndex,
      children: [
        MainMenuContent(
          habits: _habits,
          isLoading: !_habitsLoaded,
        ),
        CalendarScreen(selectedTabIndex: _currentIndex, calendarTabIndex: 1),
        const StatsScreen(),
        const AssistantScreen(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l.settingsTooltip,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
        title: TextField(
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (_) {
            // Поиск — заглушка, позже фильтрация привычек.
          },
        ),
        centerTitle: true,
        actions: [
          if (_currentIndex != 0)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l.closeButton,
              onPressed: () => setState(() => _currentIndex = 0),
            ),
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: l.subscriptionTitle,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.subscriptionTitle),
                  content: Text(l.subscriptionBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l.closeButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == 0 ? 0 : _currentIndex - 1,
        onTap: (index) => setState(() => _currentIndex = index + 1),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            label: l.tabCalendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            label: l.tabStats,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help_outline),
            label: l.tabAssistant,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.small(
              onPressed: () {
                // Добавить привычку — заглушка.
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

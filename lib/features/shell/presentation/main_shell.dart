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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return MainMenuContent(
          habits: _habits,
          isLoading: !_habitsLoaded,
        );
      case 1:
        return const CalendarScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const AssistantScreen();
      default:
        return MainMenuContent(
          habits: _habits,
          isLoading: !_habitsLoaded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
      body: _buildBody(),
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

import '../models/habit.dart';
import '../persistence/habits_persistence.dart';

/// Репозиторий привычек.
/// Хранит данные в памяти и сохраняет в SharedPreferences.
/// Синглтон, чтобы онбординг и MainShell использовали один экземпляр.
class HabitsRepository {
  HabitsRepository._();
  static final HabitsRepository instance = HabitsRepository._();

  final List<Habit> _habits = [];
  bool _loaded = false;

  Future<List<Habit>> getHabits() async {
    if (!_loaded) {
      final loaded = await HabitsPersistence.load();
      _habits.clear();
      _habits.addAll(loaded);
      _loaded = true;
    }
    return List<Habit>.from(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    _habits.insert(0, habit);
    await HabitsPersistence.save(_habits);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
      await HabitsPersistence.save(_habits);
    }
  }

  Future<void> reorderHabits(List<Habit> newOrder) async {
    if (newOrder.length != _habits.length) return;
    final ids = newOrder.map((h) => h.id).toSet();
    if (ids.length != _habits.length) return;
    _habits
      ..clear()
      ..addAll(newOrder);
    await HabitsPersistence.save(_habits);
  }
}

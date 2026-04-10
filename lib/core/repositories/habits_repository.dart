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

  /// Удаляет дубликаты по `id`, сохраняя первый встретившийся элемент.
  /// Возвращает true, если список изменился.
  bool _dedupeByIdInPlace(List<Habit> list) {
    final seen = <String>{};
    final before = list.length;
    list.removeWhere((h) {
      if (h.id.isEmpty) return false;
      if (seen.contains(h.id)) return true;
      seen.add(h.id);
      return false;
    });
    return list.length != before;
  }

  Future<List<Habit>> getHabits() async {
    if (!_loaded) {
      final loaded = await HabitsPersistence.load();
      _habits.clear();
      _habits.addAll(loaded);
      final changed = _dedupeByIdInPlace(_habits);
      _loaded = true;
      // Если нашли дубликаты (обычно после старого бага двойного сохранения) —
      // сохраняем очищенный список, чтобы не ловить GlobalKey конфликт в UI.
      if (changed) {
        await HabitsPersistence.save(_habits);
      }
    }
    return List<Habit>.from(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    // Защита от дубликатов по id.
    _habits.removeWhere((h) => h.id == habit.id && habit.id.isNotEmpty);
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

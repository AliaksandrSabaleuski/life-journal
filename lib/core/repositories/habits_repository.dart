import '../models/habit.dart';

/// Репозиторий привычек.
/// Сейчас хранит данные только в памяти и НЕ содержит предзаполненных моков.
class HabitsRepository {
  HabitsRepository();

  final List<Habit> _habits = [];

  Future<List<Habit>> getHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List<Habit>.from(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
    }
  }
}

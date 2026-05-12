import 'package:hive_ce/hive.dart';
import '../task_repository.dart';

class TaskLocalDatabase {
  static Box get _box => Hive.box('tasks');

  static List<Task> getTasks() {
    List<Task> tasks = [];
    for (int i = 0; i < _box.length; i++) {
      final map = _box.getAt(i);
      if (map != null) {
        tasks.add(Task.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return tasks;
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();
    for (var task in tasks) {
      await _box.add(task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    await _box.add(task.toMap());
  }

  static Future<void> updateTask(Task task) async {
    for (int i = 0; i < _box.length; i++) {
      final map = Map<String, dynamic>.from(_box.getAt(i));
      if (map['id'] == task.id) {
        await _box.putAt(i, task.toMap());
        return;
      }
    }
  }

  static Future<void> deleteTask(int id) async {
    for (int i = 0; i < _box.length; i++) {
      final map = Map<String, dynamic>.from(_box.getAt(i));
      if (map['id'] == id) {
        await _box.deleteAt(i);
        return;
      }
    }
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}

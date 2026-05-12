import '../task_api_service.dart';
import '../task_repository.dart';
import 'task_local_database.dart';

class TaskSyncService {
  static Future<List<Task>> loadInitialDataIfNeeded() async {
    if (TaskLocalDatabase.isEmpty()) {
      final tasks = await TaskApiService.fetchTasks();
      await TaskLocalDatabase.saveTasks(tasks);
    }
    return TaskLocalDatabase.getTasks();
  }
}

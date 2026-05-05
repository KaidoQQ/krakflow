import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task_repository.dart';

class TaskApiService {
  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/todos'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> todosJson = data['todos'];

      final random = Random();
      final priorities = ['wysoki', 'średni', 'niski'];
      final deadlines = ['dzisiaj', 'jutro', 'za 2 dni', 'w przyszłym tygodniu'];

      return todosJson.map((json) {
        return Task(
          title: json['todo'] as String,
          done: json['completed'] as bool,
          priority: priorities[random.nextInt(priorities.length)],
          deadline: deadlines[random.nextInt(deadlines.length)],
        );
      }).toList();
    } else {
      throw Exception('Nie udało się pobrać zadań: Błąd ${response.statusCode}');
    }
  }
}

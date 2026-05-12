

class Task {
  int id;
  String title;
  String deadline;
  bool done;
  String priority;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline,
      'done': done,
      'priority': priority,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      deadline: map['deadline'] as String,
      done: map['done'] as bool,
      priority: map['priority'] as String,
    );
  }
}

class TaskRepository {
  static List<Task> tasks = [];
}
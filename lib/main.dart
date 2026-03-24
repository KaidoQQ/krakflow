import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final List<Task> tasks = [
    Task(title: "Przygotować prezentację", deadline: "jutro", done: false, priority: "wysoki"),
    Task(title: "Oddać raport z laboratoriów", deadline: "dzisiaj", done: true, priority: "wysoki"),
    Task(title: "Powtórzyć widgety Flutter", deadline: "w piątek", done: false, priority: "średni"),
    Task(title: "Napisać notatki do kolokwium", deadline: "w weekend", done: false, priority: "niski"),
  ];

  @override
  Widget build(BuildContext context) {
    int doneCount = tasks.where((t) => t.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("KrakFlow"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masz dziś ${tasks.length} zadania (wykonano: $doneCount)",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: tasks.map((task) {
                    return TaskCard(
                      title: task.title,
                      subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                      icon: task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}


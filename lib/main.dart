import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MojEkran(),
    );
  }
}

class MojEkran extends StatefulWidget {

  const MojEkran({super.key});

  @override
  State<StatefulWidget> createState() => _MojEkranState();

  }

class _MojEkranState extends State<MojEkran>{
  @override
    Widget build(BuildContext context) {
      int doneCount = TaskRepository.tasks.where((t) => t.done).length;

      return Scaffold(
        appBar: AppBar(
          title: const Text("KrakFlow"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masz dziś ${TaskRepository.tasks.length} zadania (wykonano: $doneCount)",
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
                  children: TaskRepository.tasks.map((task) {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final Task? newTask = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskScreen(),
              ),
            );

            if (newTask != null){
             setState(() {
               TaskRepository.tasks.add(newTask);
             });
            }
          },
          child: const Icon(Icons.add),
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

class AddTaskScreen extends StatelessWidget{
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytul zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Deadline zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet zadania",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );
                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        )
      )
    );
  }
}

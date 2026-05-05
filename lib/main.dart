import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class _MojEkranState extends State<MojEkran> {
  String _filter = 'Wszystkie';

  List<Task> get filteredTasks {
    if (_filter == 'Do wykonania') {
      return TaskRepository.tasks.where((t) => !t.done).toList();
    } else if (_filter == 'Wykonane') {
      return TaskRepository.tasks.where((t) => t.done).toList();
    }
    return TaskRepository.tasks;
  }

  @override
  Widget build(BuildContext context) {
    int doneCount = TaskRepository.tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: TaskRepository.tasks.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Potwierdzenie"),
                        content: const Text("Usunąć wszystkie zadania?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Anuluj"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                TaskRepository.tasks.clear();
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Wszystkie zadania usunięte")),
                              );
                            },
                            child: const Text("Usuń"),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
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
            FilterBar(
              currentFilter: _filter,
              onFilterChanged: (filter) {
                setState(() {
                  _filter = filter;
                });
              },
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
                children: filteredTasks.map((task) {
                  return Dismissible(
                    key: Key(task.title + task.deadline + task.hashCode.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Zadanie '${task.title}' usunięte")),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: TaskCard(
                      task: task,
                      onCheckboxChanged: (val) {
                        setState(() {
                          task.done = val ?? false;
                        });
                      },
                      onTap: () async {
                        final updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        );
                        if (updatedTask != null) {
                          setState(() {});
                        }
                      },
                    ),
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
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(),
            ),
          );

          if (newTask != null) {
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

class FilterBar extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton("Wszystkie"),
        _buildButton("Do wykonania"),
        _buildButton("Wykonane"),
      ],
    );
  }

  Widget _buildButton(String title) {
    final isActive = currentFilter == title;
    return TextButton(
      onPressed: () => onFilterChanged(title),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.deepPurple,
        backgroundColor: isActive ? Colors.deepPurple : Colors.transparent,
      ),
      child: Text(title),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onCheckboxChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'wysoki':
        priorityColor = Colors.red;
        break;
      case 'średni':
        priorityColor = Colors.orange;
        break;
      case 'niski':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.done,
          onChanged: onCheckboxChanged,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Row(
          children: [
            Text("Termin: ${task.deadline} | Priorytet: "),
            Text(
              task.priority,
              style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Nowe zadanie"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Tytuł zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deadlineController,
                  decoration: const InputDecoration(
                    labelText: "Termin zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(
                    labelText: "Priorytet zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
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
                  child: const Text("Zapisz"),
                ),
              ],
            )));
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }
  
  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.task.title = titleController.text;
                widget.task.deadline = deadlineController.text;
                widget.task.priority = priorityController.text;
                Navigator.pop(context, widget.task);
              },
              child: const Text("Zapisz"),
            ),
          ],
        )
      )
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'task_repository.dart';
import 'services/task_local_database.dart';
import 'services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasks');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalCount = 0;
  int doneCount = 0;
  int remainingCount = 0;

  void updateCounters(List<Task> tasks) {
    setState(() {
      totalCount = tasks.length;
      doneCount = tasks.where((t) => t.done).length;
      remainingCount = totalCount - doneCount;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              "Zadania: $totalCount | Wykonane: $doneCount | Pozostałe: $remainingCount",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TaskListScreen(
                onTasksLoaded: updateCounters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final Function(List<Task>) onTasksLoaded;

  const TaskListScreen({super.key, required this.onTasksLoaded});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _filter = 'Wszystkie';
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<List<Task>> _loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = Future.value(TaskLocalDatabase.getTasks());
    });
  }

  List<Task> _applyFilter(List<Task> tasks) {
    if (_filter == 'Do wykonania') {
      return tasks.where((t) => !t.done).toList();
    } else if (_filter == 'Wykonane') {
      return tasks.where((t) => t.done).toList();
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onTasksLoaded(allTasks);
        });

        final filteredTasks = _applyFilter(allTasks);

        return Column(
          children: [
            FilterBar(
              currentFilter: _filter,
              onFilterChanged: (filter) {
                setState(() {
                  _filter = filter;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Dzisiejsze zadania",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: allTasks.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Potwierdzenie"),
                                  content:
                                      const Text("Usunąć wszystkie zadania?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Anuluj"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await TaskLocalDatabase
                                            .deleteAllTasks();
                                        Navigator.pop(ctx);
                                        _refreshTasks();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Wszystkie zadania usunięte")),
                                        );
                                      },
                                      child: const Text("Usuń"),
                                    ),
                                  ],
                                ),
                              );
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final Task? newTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTaskScreen(),
                          ),
                        );
                        if (newTask != null) {
                          await TaskLocalDatabase.addTask(newTask);
                          _refreshTasks();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Dismissible(
                    key: Key(task.id.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await TaskLocalDatabase.deleteTask(task.id);
                      _refreshTasks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Zadanie '${task.title}' usunięte")),
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
                      onCheckboxChanged: (val) async {
                        task.done = val ?? false;
                        await TaskLocalDatabase.updateTask(task);
                        _refreshTasks();
                      },
                      onTap: () async {
                        final updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        );
                        if (updatedTask != null) {
                          await TaskLocalDatabase.updateTask(updatedTask);
                          _refreshTasks();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
              style: TextStyle(
                  color: priorityColor, fontWeight: FontWeight.bold),
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
                      id: DateTime.now().millisecondsSinceEpoch,
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
            )));
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const TasksXApp());
}

class TasksXApp extends StatelessWidget {
  const TasksXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TasksX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF03DAC6),
          surface: const Color(0xFF1E1E1E),
        ),
        fontFamily: 'Roboto',
      ),
      home: const TasksHomeScreen(),
    );
  }
}

class Task {
  String title;
  String description;
  String time;
  String date;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.time,
    required this.date,
    this.isCompleted = false,
  });
}

class TasksHomeScreen extends StatefulWidget {
  const TasksHomeScreen({super.key});

  @override
  State<TasksHomeScreen> createState() => _TasksHomeScreenState();
}

class _TasksHomeScreenState extends State<TasksHomeScreen> {
  final List<Task> _tasks = [];

  // Controllers for the 4 inputs
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  // Task Add karne ka function
  void _addNewTask() {
    if (_titleController.text.trim().isEmpty) return;

    final formattedTime = _selectedTime.format(context); // Automatically handles AM/PM
    final formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    setState(() {
      _tasks.add(
        Task(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? 'No description' : _descController.text.trim(),
          time: formattedTime,
          date: formattedDate,
        ),
      );
    });

    _titleController.clear();
    _descController.clear();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TaskX Added! Notification scheduled 5m prior.'),
        backgroundColor: Color(0xFF6C63FF),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Date Picker Dialog
  Future<void> _pickDate(StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setModalState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time Picker Dialog (AM/PM)
  Future<void> _pickTime(StateSetter setModalState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setModalState(() {
        _selectedTime = picked;
      });
    }
  }

  // Bottom Sheet Modal for 4-Field Input
  void _showAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New TaskX ⚡',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // 1. Task Name
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Name',
                        hintText: 'e.g., Project Presentation',
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Description
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add some details...',
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 & 4. Date & Time Row
                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(setModalState),
                            icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6C63FF)),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF333333)),
                              backgroundColor: const Color(0xFF2C2C2C),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time Picker Button (AM/PM)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(setModalState),
                            icon: const Icon(Icons.access_time, size: 16, color: Color(0xFF6C63FF)),
                            label: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF333333)),
                              backgroundColor: const Color(0xFF2C2C2C),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addNewTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save TaskX', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TasksX ⚡',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checklist, size: 80, color: Color(0xFF444444)),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks yet. Tap + to add one!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : Colors.white,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: task.isCompleted,
                              activeColor: const Color(0xFF6C63FF),
                              onChanged: (val) {
                                setState(() {
                                  task.isCompleted = val!;
                                });
                              },
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Text(task.date, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 12, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Text(task.time, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _tasks.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
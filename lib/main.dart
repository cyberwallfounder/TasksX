import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/initialize_time_zones.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ==========================================
// NOTIFICATION SERVICE (Singleton)
// ==========================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Android 13+ permission request
  Future<void> requestPermission() async {
    if (!kIsWeb) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  // Schedule notification 5 minutes before the task deadline
  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final fiveMinutesBefore = scheduledTime.subtract(const Duration(minutes: 5));

    if (fiveMinutesBefore.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'VaultX Alert: $title',
      body,
      tz.TZDateTime.from(fiveMinutesBefore, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasksx_channel_id',
          'TasksX Notifications',
          channelDescription: 'Reminds you 5 minutes before task deadline',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

// ==========================================
// MAIN APP ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().initNotification();
  await NotificationService().requestPermission();

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
        scaffoldBackgroundColor: const Color(0xFF0F1115), // VaultX Dark Theme
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF181B22),
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      home: const TaskHomeScreen(),
    );
  }
}

// ==========================================
// TASK MODEL
// ==========================================
class TaskItem {
  final String title;
  final String description;
  final DateTime dateTime;

  TaskItem({
    required this.title,
    required this.description,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        title: json['title'],
        description: json['description'],
        dateTime: DateTime.parse(json['dateTime']),
      );
}

// ==========================================
// HOME SCREEN & UI
// ==========================================
class TaskHomeScreen extends StatefulWidget {
  const TaskHomeScreen({super.key});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  List<TaskItem> _tasks = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from SharedPreferences (Offline-first)
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('saved_tasks');
    if (tasksString != null) {
      final List decoded = jsonDecode(tasksString);
      setState(() {
        _tasks = decoded.map((item) => TaskItem.fromJson(item)).toList();
      });
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('saved_tasks', encoded);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createTask() {
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields, date, and time!')),
      );
      return;
    }

    final DateTime finalTaskDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (finalTaskDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select past time/date!')),
      );
      return;
    }

    final newTask = TaskItem(
      title: _titleController.text,
      description: _descController.text,
      dateTime: finalTaskDateTime,
    );

    setState(() {
      _tasks.add(newTask);
    });
    _saveTasks();

    // Schedule local notification 5 minutes prior
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    NotificationService().scheduleTaskNotification(
      id: notificationId,
      title: newTask.title,
      body: newTask.description.isNotEmpty ? newTask.description : 'Task is starting in 5 minutes!',
      scheduledTime: finalTaskDateTime,
    );

    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task Saved & 5-Min Notification Scheduled! 🚀')),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New VaultX Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  filled: true,
                  fillColor: const Color(0xFF222630),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: const Color(0xFF222630),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(context),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _createTask,
                  child: const Text('Save & Set 5-Min Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TasksX // VaultX', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF181B22),
        elevation: 0,
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Text(
                'No active tasks in the Vault.\nTap "+" to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(task.description, style: TextStyle(color: Colors.grey[400])),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.alarm, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'Due: ${task.dateTime.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTaskSheet(context),
      ),
    );
  }
}

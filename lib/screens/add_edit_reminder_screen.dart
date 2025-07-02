import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // Ensure flutterLocalNotificationsPlugin is declared there

class AddEditReminderScreen extends StatefulWidget {
  final DocumentSnapshot? doc; // null = add, non-null = edit

  const AddEditReminderScreen({Key? key, this.doc}) : super(key: key);

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  TimeOfDay? _time;

  final CollectionReference remindersRef =
  FirebaseFirestore.instance.collection('medication_reminders');

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final data = widget.doc!.data()! as Map<String, dynamic>;
      _nameController = TextEditingController(text: data['name'] ?? '');
      _dosageController = TextEditingController(text: data['dosage'] ?? '');
      final timestamp = data['time'] as Timestamp?;
      if (timestamp != null) {
        final dt = timestamp.toDate();
        _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    } else {
      _nameController = TextEditingController();
      _dosageController = TextEditingController();
      _time = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _scheduleNotification(String title, DateTime dateTime) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Medication Reminder',
      title,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_channel',
          'Medication Reminders',
          channelDescription: 'Reminders for medication times',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }



  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate() || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select time')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final now = DateTime.now();
    final reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time!.hour,
      _time!.minute,
    );

    final data = {
      'name': _nameController.text.trim(),
      'dosage': _dosageController.text.trim(),
      'time': Timestamp.fromDate(reminderDateTime),
      'userId': user.uid,
    };

    try {
      if (widget.doc == null) {
        await remindersRef.add(data);
      } else {
        await remindersRef.doc(widget.doc!.id).update(data);
      }

      await _scheduleNotification(
        'Take ${_nameController.text.trim()} - ${_dosageController.text.trim()}',
        reminderDateTime,
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doc != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Reminder Time: '),
                  Text(
                    _time != null ? _time!.format(context) : 'No time selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: const Text('Select Time'),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveReminder,
                child: Text(isEditing ? 'Update Reminder' : 'Add Reminder'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_edit_reminder_screen.dart';
import 'weight_tracker_screen.dart';
// import 'bmi_calculator_screen.dart'; // Make sure this exists
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final remindersQuery = FirebaseFirestore.instance
        .collection('medication_reminders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('time');

    final List<Widget> pages = [
      // Reminder Page
      StreamBuilder<QuerySnapshot>(
        stream: remindersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No medication reminders yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;

              final name = data['name'] ?? 'No name';
              final dosage = data['dosage'] ?? 'No dosage';
              final timestamp = data['time'] as Timestamp?;
              final timeStr = timestamp != null
                  ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
                  : 'No time';

              return ListTile(
                title: Text(name),
                subtitle: Text('Dosage: $dosage\nTime: $timeStr'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditReminderScreen(doc: doc),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Reminder'),
                            content: const Text('Are you sure you want to delete this reminder?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await FirebaseFirestore.instance
                              .collection('medication_reminders')
                              .doc(doc.id)
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // Weight Tracker Page
      const WeightTrackerScreen(),

      // BMI Calculator Page
      //const BMICalculatorScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Reminders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight), label: 'Weight Tracker'),
          BottomNavigationBarItem(
              icon: Icon(Icons.accessibility), label: 'BMI Calculator'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditReminderScreen()),
          );
        },
      )
          : null,
    );
  }
}

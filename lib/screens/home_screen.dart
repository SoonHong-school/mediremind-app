import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_edit_reminder_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // If somehow user is null, redirect to login (or handle gracefully)
      return Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final remindersQuery = FirebaseFirestore.instance
        .collection('medication_reminders')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('time'); // sort by time

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind Home'),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: remindersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reminders: ${snapshot.error}'));
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
                          await FirebaseFirestore.instance.collection('medication_reminders').doc(doc.id).delete();
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditReminderScreen()),
          );
        },
      ),
    );
  }
}

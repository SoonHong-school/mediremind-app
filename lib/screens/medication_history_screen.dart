import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicationHistoryScreen extends StatelessWidget {
  const MedicationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication History')),
        body: const Center(child: Text('User not logged in')),
      );
    }

    final logsQuery = FirebaseFirestore.instance
        .collection('medication_logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timeTaken', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: logsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown';
              final dosage = data['dosage'] ?? '';
              final status = data['status'] ?? 'Unknown';
              final timestamp = (data['timeTaken'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text('$name - $dosage'),
                subtitle: Text(
                  timestamp != null
                      ? timestamp.toLocal().toString().split('.')[0]
                      : 'No time',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'Taken' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Log'),
                            content: const Text('Are you sure you want to delete this log?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await FirebaseFirestore.instance
                              .collection('medication_logs')
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
    );
  }
}

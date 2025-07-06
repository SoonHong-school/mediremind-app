import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicationLogScreen extends StatelessWidget {
  const MedicationLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final logRef = FirebaseFirestore.instance
        .collection('medication_logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('takenAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: logRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No medication logs yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;
              final name = data['medicationName'] ?? 'No name';
              final dosage = data['dosage'] ?? 'No dosage';
              final takenAt = (data['takenAt'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(name),
                subtitle: Text('Dosage: $dosage\nTaken at: ${takenAt != null ? takenAt.toString() : "N/A"}'),
              );
            },
          );
        },
      ),
    );
  }
}

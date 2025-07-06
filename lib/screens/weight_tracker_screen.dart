// lib/screens/weight_tracker_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  final _weightController = TextEditingController();
  final CollectionReference _weightRef = FirebaseFirestore.instance.collection('weight_logs');

  Future<void> _addWeightEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _weightController.text.trim().isEmpty) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null) return;

    await _weightRef.add({
      'weight': weight,
      'timestamp': Timestamp.now(),
      'userId': user.uid,
    });

    _weightController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Enter your weight (kg)'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addWeightEntry,
                  child: const Text('Add'),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _weightRef
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No entries yet.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final weight = data['weight'];
                      final timestamp = (data['timestamp'] as Timestamp).toDate();
                      return ListTile(
                        leading: const Icon(Icons.monitor_weight),
                        title: Text("$weight kg"),
<<<<<<< Updated upstream
                        subtitle: Text('${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'),
=======
                        subtitle: Text(
                          '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Entry"),
                                content: const Text("Are you sure you want to delete this weight entry?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel")),
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Delete")),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _weightRef.doc(doc.id).delete();
                            }
                          },
                        ),
>>>>>>> Stashed changes
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

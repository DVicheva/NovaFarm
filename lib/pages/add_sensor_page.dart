import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSensorPage extends StatelessWidget {
  final String userId;

  const AddSensorPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    void addSensor() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sensors')
          .add({
        'name': nameController.text.trim(),
        'value': [],
        'lastUpdated': DateTime.now(),
      });
      Navigator.pop(context); // Retour à la page précédente
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un Capteur")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom du Capteur"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addSensor,
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }
}

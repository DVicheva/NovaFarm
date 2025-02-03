import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAutomatePage extends StatelessWidget {
  final String userId;

  const AddAutomatePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    void addAutomate() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('automates')
          .add({
        'name': nameController.text.trim(),
      });
      Navigator.pop(context); // Retour à la page précédente
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un Automate")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom de l'Automate"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addAutomate,
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }
}

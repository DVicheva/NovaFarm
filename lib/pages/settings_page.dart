import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_page_widget.dart';

class SettingsPage extends StatelessWidget {
  final String userId;

  const SettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 2, // Index pour la page Paramètres
      userId: userId,
      child: Scaffold(
        appBar: AppBar(title: const Text("Paramètres")),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Erreur lors du chargement des données"));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final firstName = userData['firstName'] ?? "Non renseigné";
            final lastName = userData['lastName'] ?? "Non renseigné";
            final email = userData['email'] ?? "Non renseigné";

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informations utilisateur", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Email : $email", style: const TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

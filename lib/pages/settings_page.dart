import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_page_widget.dart';

class SettingsPage extends StatefulWidget {
  final String userId;

  const SettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Valeur locale de l'abonnement, par défaut "standard"
  String _subscription = "standard";

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 2, // Index pour la page Paramètres
      userId: widget.userId,
      child: Scaffold(
        appBar: AppBar(title: const Text("Paramètres")),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Erreur lors du chargement des données"));
            }

            // Récupération des données utilisateur depuis Firestore
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final firstName = userData['firstName'] ?? "Non renseigné";
            final lastName = userData['lastName'] ?? "Non renseigné";
            final email = userData['email'] ?? "Non renseigné";

            // On récupère la valeur de subscription depuis Firestore, par défaut "standard"
            final firebaseSubscription = userData['subscription'] ?? "standard";

            // Mise à jour de la variable locale si nécessaire (sans provoquer de boucle infinie)
            if (_subscription != firebaseSubscription) {
              // On utilise addPostFrameCallback pour éviter de modifier l'état pendant la construction
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _subscription = firebaseSubscription;
                  });
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informations utilisateur",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text("Email : $email", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  const Text(
                    "Abonnement",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  // Bouton radio pour l'abonnement "Standard"
                  RadioListTile<String>(
                    title: const Text("Standard"),
                    value: "standard",
                    groupValue: _subscription,
                    onChanged: (value) {
                      if (value != null) {
                        _updateSubscription(value);
                      }
                    },
                  ),
                  // Bouton radio pour l'abonnement "Premium"
                  RadioListTile<String>(
                    title: const Text("Premium"),
                    value: "premium",
                    groupValue: _subscription,
                    onChanged: (value) {
                      if (value != null) {
                        _updateSubscription(value);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Met à jour la valeur de l'abonnement dans Firestore et dans l'état local.
  void _updateSubscription(String newSubscription) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'subscription': newSubscription})
        .then((_) {
      setState(() {
        _subscription = newSubscription;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Abonnement mis à jour en $newSubscription")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour de l'abonnement")),
      );
    });
  }
}

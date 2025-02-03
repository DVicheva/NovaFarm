import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_farm/pages/add_parcel_page.dart';
import 'package:nova_farm/pages/add_sensor_page.dart';
import 'package:nova_farm/pages/add_automate_page.dart';
import 'package:nova_farm/pages/add_weather_location_page.dart';
import '../widgets/parcel_card.dart';
import '../widgets/weather_widget.dart';
import '../widgets/base_page_widget.dart';

class HomePage extends StatelessWidget {
  final String userId; // ID de l'utilisateur connecté

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 1, // Index de la page actuelle
      userId: userId,
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Chargement...");
              }
              if (snapshot.hasError) {
                return const Text("Erreur");
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("Utilisateur inconnu");
              }

              // Récupère le champ "username" ou affiche un nom par défaut
              final userName = snapshot.data!.get('username') ?? "Utilisateur";
              return Text(userName);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddOptions(context); // Affiche les options d'ajout
              },
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Aucun emplacement météo défini."));
            }

            final userLocations = snapshot.data!['locations'] as List<dynamic>? ?? [];
            final locations = userLocations.whereType<Map<String, dynamic>>().toList();

            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                // Section Météo
                if (locations.isNotEmpty) ...[
                  const Text(
                    "Prévisions météo",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: locations
                        .map<Widget>((location) => WeatherWidget(
                              latitude: location['latitude'],
                              longitude: location['longitude'],
                              userId: userId, // Ajout du userId requis
                            ))
                        .toList(), // Correction de la conversion en List<Widget>
                  ),
                  const Divider(),
                ],

                // Section État des parcelles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "État des parcelles",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('parcels')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final parcels = snapshot.data!.docs;
                    if (parcels.isEmpty) {
                      return const Center(
                        child: Text("Aucune parcelle enregistrée."),
                      );
                    }
                    return Column(
                      children: parcels.map<Widget>((parcel) {
                        // Convertit la snapshot en Map
                        final parcelData = parcel.data() as Map<String, dynamic>;

                        // Injecte l'ID Firestore dans le map,
                        // pour pouvoir faire doc(widget.parcel['id']) plus tard
                        parcelData['id'] = parcel.id;

                        return ParcelCard(
                          parcel: parcelData,
                          userId: userId,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.landscape),
              title: const Text("Ajouter une parcelle"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddParcelPage(userId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sensors),
              title: const Text("Ajouter un capteur"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSensorPage(userId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: const Text("Ajouter un automate"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAutomatePage(userId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Ajouter un emplacement météo"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWeatherLocationPage(userId: userId),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/base_page_widget.dart';

class AddParcelPage extends StatefulWidget {
  final String userId;

  const AddParcelPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AddParcelPageState createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  String? selectedAutomate;
  Map<String, String> selectedSensors = {}; // Stocke ID et Nom des capteurs sélectionnés

  Future<void> addParcel() async {
    String parcelName = nameController.text.trim();
    if (parcelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom pour la parcelle.')),
      );
      return;
    }

    double? latitude = double.tryParse(latitudeController.text.trim());
    double? longitude = double.tryParse(longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir des coordonnées valides ou utiliser votre position actuelle.')),
      );
      return;
    }

    GeoPoint userLocation = GeoPoint(latitude, longitude);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('parcels')
        .add({
      'name': parcelName,
      'location': userLocation,
      'automate': selectedAutomate ?? "Aucun",
      'sensors': selectedSensors, // Stocke {id: name} au lieu d'une simple liste
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parcelle ajoutée avec succès !')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: null,
      userId: widget.userId,
      child: Scaffold(
        appBar: AppBar(title: const Text("Ajouter une Parcelle")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nom de la Parcelle"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    GeoPoint? userLocation = await getUserLocation();
                    if (userLocation != null) {
                      latitudeController.text = userLocation.latitude.toString();
                      longitudeController.text = userLocation.longitude.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Position détectée : ${userLocation.latitude}, ${userLocation.longitude}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Impossible d\'obtenir la position actuelle.')),
                      );
                    }
                  },
                  child: const Text("Utiliser ma position actuelle"),
                ),
                TextField(
                  controller: latitudeController,
                  decoration: const InputDecoration(labelText: "Latitude"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: longitudeController,
                  decoration: const InputDecoration(labelText: "Longitude"),
                  keyboardType: TextInputType.number,
                ),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('automates')
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final automates = snapshot.data!.docs;

                    return DropdownButton<String>(
                      value: selectedAutomate,
                      onChanged: (value) {
                        setState(() {
                          selectedAutomate = value;
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: "Aucun",
                          child: Text("Aucun automate"),
                        ),
                        ...automates.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc.id),
                          );
                        }).toList(),
                      ],
                      hint: const Text("Choisir un Automate"),
                    );
                  },
                ),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('sensors')
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final sensors = snapshot.data!.docs;

                    return Wrap(
                      children: sensors.map((doc) {
                        return CheckboxListTile(
                          value: selectedSensors.containsKey(doc.id),
                          title: Text(doc.id), // Affiche l'ID comme nom
                          onChanged: (selected) {
                            setState(() {
                              if (selected!) {
                                selectedSensors[doc.id] = doc.id; // Stocke ID comme Nom
                              } else {
                                selectedSensors.remove(doc.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: addParcel,
                  child: const Text("Ajouter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fonction pour récupérer la localisation GPS
Future<GeoPoint?> getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return null;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return GeoPoint(position.latitude, position.longitude);
}

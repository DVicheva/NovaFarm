import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AddWeatherLocationPage extends StatefulWidget {
  final String userId;

  const AddWeatherLocationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AddWeatherLocationPageState createState() => _AddWeatherLocationPageState();
}

class _AddWeatherLocationPageState extends State<AddWeatherLocationPage> {
  final TextEditingController cityNameController = TextEditingController();
  String? selectedLocation;
  GeoPoint? selectedGeoPoint;
  List<Map<String, dynamic>> weatherData = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  /// Obtenir la position GPS de l'utilisateur
  Future<GeoPoint?> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Obtenir les coordonnées GPS à partir d'un nom de ville
  Future<GeoPoint?> getGeoPointFromCity(String cityName) async {
    final url = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&format=json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final result = data['results'][0];
        return GeoPoint(result['latitude'], result['longitude']);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ville introuvable')));
    return null;
  }

  /// Enregistrer l'emplacement météo dans Firebase
  void saveWeatherLocation() async {
    if (selectedGeoPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un emplacement valide')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'locations': FieldValue.arrayUnion([
        {
          'latitude': selectedGeoPoint!.latitude,
          'longitude': selectedGeoPoint!.longitude
        }
      ])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emplacement météo ajouté avec succès !')),
    );

    // Réinitialiser les champs après l'ajout
    setState(() {
      selectedLocation = null;
      selectedGeoPoint = null;
      cityNameController.clear();
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un emplacement météo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                GeoPoint? location = await getUserLocation();
                if (location != null) {
                  setState(() {
                    selectedGeoPoint = location;
                    selectedLocation = "Position actuelle : ${location.latitude}, ${location.longitude}";
                  });
                }
              },
              child: const Text("Utiliser ma position actuelle"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cityNameController,
              decoration: const InputDecoration(labelText: "Nom de la ville", hintText: "Exemple : Paris"),
              onSubmitted: (value) async {
                GeoPoint? geoPoint = await getGeoPointFromCity(value.trim());
                if (geoPoint != null) {
                  setState(() {
                    selectedGeoPoint = geoPoint;
                    selectedLocation = "Ville sélectionnée : $value (${geoPoint.latitude}, ${geoPoint.longitude})";
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (selectedLocation != null)
              Text(
                selectedLocation!,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveWeatherLocation,
              child: const Text("Ajouter l'emplacement"),
            ),
          ],
        ),
      ),
    );
  }
}

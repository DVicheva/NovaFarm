import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeatherWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String userId;

  const WeatherWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.userId,
  }) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String? cityName;
  List<Map<String, dynamic>>? weatherData;

  @override
  void initState() {
    super.initState();
    _fetchCityName();
    _fetchWeatherData();
  }

  /// 🔹 Récupère le nom de la ville avec l'API OpenStreetMap
  Future<void> _fetchCityName() async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${widget.latitude}&lon=${widget.longitude}&zoom=10');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cityName = data["address"]["city"] ??
              data["address"]["town"] ??
              data["address"]["village"] ??
              "Lieu inconnu";
        });
      } else {
        setState(() {
          cityName = "Lieu inconnu";
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération du nom de la ville : $e");
      setState(() {
        cityName = "Lieu inconnu";
      });
    }
  }

  /// 🔹 Récupère les données météo
  Future<void> _fetchWeatherData() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=${widget.latitude}&longitude=${widget.longitude}&daily=temperature_2m_max,temperature_2m_min&timezone=auto',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> forecast = [];

        for (int i = 0; i < data['daily']['time'].length; i++) {
          final rawDate = data['daily']['time'][i];
          final parsedDate = DateTime.parse(rawDate);
          final formattedDate = DateFormat('EEEE d MMM', 'fr_FR').format(parsedDate);

          final maxTemp = data['daily']['temperature_2m_max'][i];
          final minTemp = data['daily']['temperature_2m_min'][i];

          forecast.add({
            'date': formattedDate,
            'maxTemp': maxTemp,
            'minTemp': minTemp,
            'icon': Icons.wb_sunny, // Icône météo par défaut
          });
        }

        setState(() {
          weatherData = forecast;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des données météo : $e");
    }
  }

  /// 🔹 Supprime l'emplacement météo de la base de données
  Future<void> _deleteWeatherLocation() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    await docRef.update({
      'locations': FieldValue.arrayRemove([
        {
          'latitude': widget.latitude,
          'longitude': widget.longitude,
        }
      ])
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        // 🔹 Confirmation avant suppression
        final confirm = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Supprimer l'emplacement météo"),
              content: Text("Voulez-vous vraiment supprimer $cityName de la liste ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Supprimer"),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          await _deleteWeatherLocation();
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // 🔹 Affichage du nom de la ville
              Text(
                cityName ?? "Chargement...",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (weatherData == null)
                const CircularProgressIndicator()
              else
                Column(
                  children: weatherData!.map((dayWeather) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dayWeather['date']),
                          Row(
                            children: [
                              Icon(dayWeather['icon'], color: Colors.orange),
                              const SizedBox(width: 10),
                              Text("Max: ${dayWeather['maxTemp']}°C, Min: ${dayWeather['minTemp']}°C"),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

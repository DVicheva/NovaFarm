import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParcelCard extends StatefulWidget {
  final Map<String, dynamic> parcel;
  final String userId;

  const ParcelCard({
    Key? key,
    required this.parcel,
    required this.userId,
  }) : super(key: key);

  @override
  _ParcelCardState createState() => _ParcelCardState();
}

class _ParcelCardState extends State<ParcelCard> {
  String state = "unknown"; // good / medium / bad / unknown
  double humidityLimitMin = 30;
  double humidityLimitMax = 70;

  @override
  void initState() {
    super.initState();
    _fetchParcelLimits();
  }

  /// 1) Lecture des limites de la parcelle
  Future<void> _fetchParcelLimits() async {
    try {
      final parcelId = widget.parcel['id']; 
      if (parcelId == null) {
        print("❌ Pas d'ID dans la parcelle : ${widget.parcel}");
        return;
      }

      // Lecture du doc de la parcelle
      final parcelDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('parcels')
          .doc(parcelId)
          .get();

      if (!parcelDoc.exists) {
        print("❌ La parcelle $parcelId n'existe pas !");
        return;
      }

      final data = parcelDoc.data();
      if (data == null) return;

      setState(() {
        if (data.containsKey('humidityLimitMin')) {
          humidityLimitMin = (data['humidityLimitMin'] as num).toDouble();
        }
        if (data.containsKey('humidityLimitMax')) {
          humidityLimitMax = (data['humidityLimitMax'] as num).toDouble();
        }
      });

      // Une fois les limites lues, on va lire la dernière valeur du capteur
      _fetchSensorState();
    } catch (e) {
      print("❌ Erreur lecture limites : $e");
    }
  }

  /// 2) Lecture du capteur et récupération de la dernière mesure
  Future<void> _fetchSensorState() async {
    try {
      // Hypothèse : "sensors" = "CapteurA" (un simple String), 
      // ou un array contenant "CapteurA".
      final sensors = widget.parcel['sensors']; 
      if (sensors == null) {
        print("❌ Auncun sensor dans la parcelle");
        return;
      }

      // => On récupère l'ID du capteur
      late String sensorId;
      if (sensors is String) {
        // Parcelle stocke directement "CapteurA" par ex
        sensorId = sensors;
      } 
      else if (sensors is List) {
        // Si c'est un tableau
        if (sensors.isEmpty) return;
        sensorId = sensors.first; // ex: "CapteurA"
      } 
      else if (sensors is Map) {
        // ex: { "CapteurA": "CapteurA" }
        sensorId = sensors.keys.first.toString();
      } 
      else {
        print("❌ Format 'sensors' inconnu : $sensors");
        return;
      }

      print("ℹ️ sensorId = $sensorId");

      // Lecture du doc du capteur
      final sensorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('sensors')
          .doc(sensorId)
          .get();

      if (!sensorDoc.exists) {
        print("❌ Le capteur $sensorId n'existe pas !");
        return;
      }

      final sensorData = sensorDoc.data();
      if (sensorData == null || !sensorData.containsKey('value')) {
        print("❌ Le doc capteur n'a pas de champ 'value' !");
        return;
      }

      final rawList = sensorData['value'];
      if (rawList is! List) {
        print("❌ 'value' n'est pas un tableau !");
        return;
      }

      // => Ex: [ {timestamp:..., values:46}, {timestamp:..., values:46}, ... ]
      if (rawList.isEmpty) {
        print("❌ Le tableau de mesures est vide !");
        return;
      }

      // Tri par timestamp si on veut la plus récente en premier
      final measurements = rawList
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      measurements.sort((a, b) {
        // tri descendant (plus récent en premier)
        final dateA = _extractDate(a['timestamp']);
        final dateB = _extractDate(b['timestamp']);
        return dateB.compareTo(dateA);
      });

      // => La plus récente
      final lastMeasurement = measurements.first;
      final num? lastValueNum = lastMeasurement['values'];
      if (lastValueNum == null) {
        print("❌ 'values' nul dans la dernière mesure !");
        return;
      }
      final double lastValue = lastValueNum.toDouble();

      // Calcul état
      final String newState = _computeParcelState(lastValue);
      setState(() {
        state = newState;
      });
      print("✅ État calculé = $state (valeur=$lastValue)");

    } catch (e) {
      print("❌ Erreur lecture capteur : $e");
    }
  }

  /// Petite fonction pour extraire un DateTime d'un Timestamp ou d'une String
  DateTime _extractDate(dynamic rawTimestamp) {
    if (rawTimestamp is Timestamp) {
      return rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      return DateTime.parse(rawTimestamp);
    }
    // Valeur par défaut
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// 3) Compare la dernière valeur aux limites pour déterminer l'état
  String _computeParcelState(double lastValue) {
    if (lastValue >= humidityLimitMin && lastValue <= humidityLimitMax) {
      return "good";
    } 
    else {
      final bool nearMin = (lastValue < humidityLimitMin) 
          && (humidityLimitMin - lastValue).abs() <= 5;
      final bool nearMax = (lastValue > humidityLimitMax) 
          && (lastValue - humidityLimitMax).abs() <= 5;
      if (nearMin || nearMax) {
        return "medium";
      } 
      else {
        return "bad";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcelId = widget.parcel['id'];
    if (parcelId == null) {
      return _buildCard(
        title: widget.parcel['name'] ?? 'Parcelle inconnue',
        stateText: "État: (id manquant)",
        color: Colors.grey,
      );
    }

    // StreamBuilder pour écouter en temps réel les modifications des limites
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('parcels')
        .doc(parcelId)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final parcelData = snapshot.data!.data() as Map<String, dynamic>;
          if (parcelData.containsKey('humidityLimitMin')) {
            humidityLimitMin = (parcelData['humidityLimitMin'] as num).toDouble();
          }
          if (parcelData.containsKey('humidityLimitMax')) {
            humidityLimitMax = (parcelData['humidityLimitMax'] as num).toDouble();
          }
        }

        // Déterminer l'affichage selon 'state'
        Color color;
        String label;
        switch (state) {
          case 'good':
            color = Colors.green;
            label = "Bonne santé";
            break;
          case 'medium':
            color = Colors.orange;
            label = "État moyen";
            break;
          case 'bad':
            color = Colors.red;
            label = "Mauvais état";
            break;
          default:
            color = Colors.grey;
            label = "État inconnu";
        }

        return _buildCard(
          title: widget.parcel['name'] ?? 'Parcelle sans nom',
          stateText: "État: $label",
          color: color,
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String stateText,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 10,
        ),
        title: Text(title),
        subtitle: Text(stateText),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

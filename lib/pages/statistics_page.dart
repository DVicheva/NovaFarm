import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/base_page_widget.dart';

class StatisticsPage extends StatefulWidget {
  final String userId;

  const StatisticsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

  

class _StatisticsPageState extends State<StatisticsPage> {
  List<String> sensorIds = [];
  String? selectedParcelId;
  String? selectedParcelName;
 double humidityLimitMin = 30.0;
  double humidityLimitMax = 70.0;


  @override
  void initState() {
    super.initState();
    _showParcelSelectionDialog();
  }

  Future<void> _triggerIrrigation() async {
    DocumentReference automateRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('automates')
        .doc('automate_1');

    await automateRef.update({
      'automate_1.timestamp': FieldValue.serverTimestamp(), // Met à jour uniquement le timestamp
      'automate_1.value': 5, // Met à jour uniquement la valeur
      }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Arrosage déclenché et mis à jour !")),
      );
    }).catchError((error) {
      print("❌ Erreur lors de la mise à jour : $error");
    });
  }


  void _showHumidityRangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        RangeValues tempRange = RangeValues(humidityLimitMin, humidityLimitMax);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Choisissez vos limites d'humidité"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Min: ${tempRange.start.toInt()}%  -  Max: ${tempRange.end.toInt()}%",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    labels: RangeLabels(
                      "${tempRange.start.toInt()}",
                      "${tempRange.end.toInt()}",
                    ),
                    onChanged: (RangeValues newRange) {
                      setDialogState(() {
                        tempRange = newRange;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Enregistrer la nouvelle plage
                    _updateHumidityLimits(tempRange.start, tempRange.end);
                    Navigator.pop(context);
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  

  Future<void> _updateHumidityLimits(double minValue, double maxValue) async {
    if (selectedParcelId == null) return;

    await FirebaseFirestore.instance
    .collection('users')
    .doc(widget.userId)
    .collection('parcels')
    .doc(selectedParcelId!)
    .set({
      'humidityLimitMin': minValue,
      'humidityLimitMax': maxValue,
    }, SetOptions(merge: true));


    setState(() {
      humidityLimitMin = minValue;
      humidityLimitMax = maxValue;
    });
  }


  Future<void> _fetchHumidityLimits() async {
    if (selectedParcelId == null) return;

    final parcelDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('parcels')
        .doc(selectedParcelId!)
        .get();

    if (parcelDoc.exists) {
      final data = parcelDoc.data()!;
      setState(() {
        // Vérifier l'existence des champs dans la BD
        if (data.containsKey('humidityLimitMin')) {
          humidityLimitMin = (data['humidityLimitMin'] as num).toDouble();
        }
        if (data.containsKey('humidityLimitMax')) {
          humidityLimitMax = (data['humidityLimitMax'] as num).toDouble();
        }
      });
    }
  }



  /// 🔹 Affiche un popup avec la liste des parcelles de l'utilisateur
  Future<void> _showParcelSelectionDialog() async {
    final parcelsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('parcels')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sélectionner une parcelle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: parcelsSnapshot.docs.map((doc) {
              return ListTile(
                title: Text(doc['name'] ?? 'Sans Nom'),
                onTap: () {
                  setState(() {
                    selectedParcelId = doc.id;
                    selectedParcelName = doc['name'];
                    _fetchParcelSensors(doc.id);
                    _fetchHumidityLimits();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 🔹 Récupère les capteurs associés à une parcelle sélectionnée
  Future<void> _fetchParcelSensors(String parcelId) async {
    try {
      final parcelDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('parcels')
          .doc(parcelId)
          .get();

      List<String> tempSensorIds = [];

      final sensorsData = parcelDoc['sensors'];

      if (sensorsData is List) {
        tempSensorIds.addAll(sensorsData.map((sensor) => sensor.toString()));
      } else if (sensorsData is Map) {
        tempSensorIds.addAll(sensorsData.values.map((sensor) => sensor.toString()));
      }

      setState(() {
        sensorIds = tempSensorIds.toSet().toList();
      });
    } catch (e) {
      print("❌ Erreur lors de la récupération des capteurs : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      userId: widget.userId,
      currentIndex: 0,
      child: selectedParcelId == null
    ? const Center(child: Text("Sélectionnez une parcelle pour voir ses capteurs."))
    : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _triggerIrrigation,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.blue, size: 30),
                ),
                ElevatedButton(
                  onPressed: _showHumidityRangeDialog,
                  child: const Text("Définir limite d'humidité"),
                ),
              ],
            ),
          ),
          Expanded(
            child: sensorIds.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // 1) On "déplie" la liste générée par sensorIds.map(...)
                      ...sensorIds.map((sensorId) {
                        return _buildSensorGraph(sensorId);
                      }).toList(),

                      // 2) On ajoute en plus le widget IA
                      _buildIaPredictionChart(),
                      _buildRainPredictionChart()
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Construit un graphique pour un capteur donné
  Widget _buildSensorGraph(String sensorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('sensors')
          .doc(sensorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("Aucune donnée pour le capteur $sensorId."));
        }

        final sensorData = snapshot.data!;
        final rawData = sensorData['value'];

        List<Map<String, dynamic>> values = [];

        // 🔥 Vérification et conversion sécurisée des données
        if (rawData is List) {
          values = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (rawData is Map<String, dynamic>) {
          values = rawData.values.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          print("⚠️ Format inconnu pour $sensorId : $rawData");
        }

        if (values.isEmpty) {
          return const Center(child: Text("Aucune donnée à afficher."));
        }

        // 🔥 Correction du problème de Timestamp
        values.sort((a, b) {
          DateTime dateA = a['timestamp'] is Timestamp ? a['timestamp'].toDate() : DateTime.parse(a['timestamp']);
          DateTime dateB = b['timestamp'] is Timestamp ? b['timestamp'].toDate() : DateTime.parse(b['timestamp']);
          return dateA.compareTo(dateB);
        });

        // 🔥 Création des points du graphique
        final List<FlSpot> chartData = values.map((data) {
          DateTime timestamp = data['timestamp'] is Timestamp
              ? data['timestamp'].toDate()
              : DateTime.parse(data['timestamp']);

          return FlSpot(
            timestamp.millisecondsSinceEpoch.toDouble(),
            (data['values'] as num).toDouble()
          );
        }).toList();

        double minX = chartData.first.x;
        double maxX = chartData.last.x;
        double minY = chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        double maxY = chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

        DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(minX.toInt());
        DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(maxX.toInt());

        // 🔥 Récupérer les jours distincts sous forme "JJ/MM" et s'assurer qu'il y a un seul affichage
        Set<String> uniqueDates = values.map((e) {
          DateTime date = e['timestamp'] is Timestamp ? e['timestamp'].toDate() : DateTime.parse(e['timestamp']);
          return "${date.day}/${date.month}";
        }).toSet();

        String dateDisplay = uniqueDates.join(" - "); // Format final propre

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Capteur : $sensorId",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY - 5, // Légère marge pour éviter de coller au bord
                      maxY: maxY + 5,
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: ((maxY - minY) / 5).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toInt()}%",
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: ((maxY - minY) / 5).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toInt()}%",
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: maxX - minX, // Affichage uniquement aux extrémités
                            getTitlesWidget: (value, meta) {
                              DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              if (value == minX) {
                                return Text("${date.hour}h${date.minute}");
                              } else if (value == maxX) {
                                return Text("${date.hour}h${date.minute}");
                              }
                              return const SizedBox(); // Ne rien afficher pour les valeurs intermédiaires
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          String formattedDate = "${date.day}/${date.month}";

                          // 🔥 Extraire les jours uniques à afficher
                          List<String> uniqueDays = values.map((e) {
                            DateTime d = e['timestamp'] is Timestamp ? e['timestamp'].toDate() : DateTime.parse(e['timestamp']);
                            return "${d.day}/${d.month}";
                          }).toSet().toList();

                          if (uniqueDays.isEmpty) return const SizedBox(); // Pas de date affichée si liste vide

                          // 🔥 Afficher le premier jour à gauche et le second uniquement si nécessaire
                          if (formattedDate == uniqueDays.first && value == minX) {
                            return Text(
                              uniqueDays.first,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            );
                          } else if (uniqueDays.length > 1 && formattedDate == uniqueDays[1] && value > minX) {
                            return Text(
                              uniqueDays[1],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            );
                          }

                          return const SizedBox(); // Masquer toutes les autres dates
                        },
                      ),
                    ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: humidityLimitMin,
                            color: Colors.red,
                            strokeWidth: 2,
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (_) => "Min : ${humidityLimitMin.toInt()}%",
                            ),
                          ),
                          HorizontalLine(
                            y: humidityLimitMax,
                            color: Colors.green,
                            strokeWidth: 2,
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (_) => "Max : ${humidityLimitMax.toInt()}%",
                            ),
                          ),
                        ],
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                          dotData: FlDotData(show: true), // Affiche les points de mesure
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIaPredictionChart() {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('prediction_ia')
        .doc('prediction_1')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text("Aucune donnée IA."));
      }

      final Map<String, dynamic>? docData =
          snapshot.data!.data() as Map<String, dynamic>?;
      if (docData == null) {
        return const Center(child: Text("Document IA vide."));
      }

      // Récupération du tableau
      final myArray = docData['myArray'];
      if (myArray is! List) {
        return const Text("Le champ 'myArray' n'est pas un tableau.");
      }
      if (myArray.isEmpty) {
        return const Text("Le tableau 'myArray' est vide.");
      }

      // Pour chaque indice i (0 à 23), on crée un BarChartGroupData
      List<BarChartGroupData> barGroups = [];
      for (int i = 0; i < myArray.length; i++) {
        final valNum = myArray[i] as num; // valeurs : double / int
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: valNum.toDouble(),
                width: 10,
                color: Colors.blue,
              )
            ],
          ),
        );
      }

      // On peut afficher ces 24 barres avec l'heure correspondante
      // Admettons qu'on parte de l'heure actuelle (arrondie) :
      final now = DateTime.now();
      int startHour = now.hour; // on part de l'heure en cours

      return Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Prévisions IA (prochaines 24h)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          
                          // On part de l'heure courante : (startHour + i) % 24
                          getTitlesWidget: (value, meta) {
                            final hour = (startHour + value.toInt()) % 24;
                            return Text("$hour h",
                                style: const TextStyle(fontSize: 11));
                          },

                          reservedSize: 14,
                          interval: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildRainPredictionChart() {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('prediction_pluie')
        .doc('pluie_1')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text("Aucune donnée de pluie IA."));
      }

      final Map<String, dynamic>? docData =
          snapshot.data!.data() as Map<String, dynamic>?;
      if (docData == null) {
        return const Center(child: Text("Document pluie IA vide."));
      }

      // Récupération du tableau
      final myArray = docData['myArray'];
      if (myArray is! List) {
        return const Text("Le champ 'myArray' n'est pas un tableau.");
      }
      if (myArray.isEmpty) {
        return const Text("Le tableau 'myArray' est vide.");
      }

      // Création des BarChartGroupData & récupération de la valeur max
      List<BarChartGroupData> barGroups = [];
      double maxVal = 0;
      for (int i = 0; i < myArray.length; i++) {
        final valNum = myArray[i] as num; // double/int
        final barValue = valNum.toDouble();
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: barValue,
                width: 10,
                color: Colors.blue,
              )
            ],
          ),
        );

        if (barValue > maxVal) {
          maxVal = barValue;
        }
      }

      // Ajuste la plage verticale pour plus de visibilité
      final double topPadding = maxVal > 0 ? (maxVal * 0.1) : 5;
      final double yMax = maxVal + topPadding; // Espace en haut du graphe

      // Intervalle de l'axe vertical
      // (on veut ~5 ou 6 lignes max, d’où la division par 5 ; ajustez selon vos besoins)
      final double leftInterval = maxVal > 0 ? (yMax / 5).ceilToDouble() : 1;

      // On peut afficher 24 valeurs : i=0..23
      final now = DateTime.now();
      int startHour = now.hour; // point de départ (vous pouvez ajuster)

      return Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Prévisions de pluie (prochaines 24h)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    // 🔹 On indique une plage verticale
                    minY: 0,
                    maxY: yMax,
                    barGroups: barGroups,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: leftInterval, // notre intervalle
                          getTitlesWidget: (value, meta) {
                            // Affiche seulement des valeurs entières (ou vous pouvez limiter les décimales)
                            return Text("${value.toInt()}");
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,  // on génère un label pour chaque barre
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            // On n'affiche le label que si l'index est multiple de 3
                            if (value % 3 != 0) {
                              return const SizedBox();
                            }
                            final hour = (startHour + value.toInt()) % 24;
                            return Text(
                              "$hour h",
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

}



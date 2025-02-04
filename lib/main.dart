import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nova_farm/pages/add_automate_page.dart';
import 'package:nova_farm/pages/add_parcel_page.dart';
import 'package:nova_farm/pages/add_sensor_page.dart';
import 'package:nova_farm/pages/home_page.dart';
import 'package:nova_farm/pages/login_page.dart';
import 'package:nova_farm/pages/settings_page.dart';
import 'package:nova_farm/pages/statistics_page.dart';
import 'firebase_web_options.dart';
import 'pages/add_weather_location_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('fr_FR', null);
  runApp(MyApp());
  
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'NovaFarm',
    theme: ThemeData(
      fontFamily: 'Times New Roman',
      useMaterial3: true, // Active le style Material 3
      hintColor: const Color.fromARGB(255, 43, 180, 180),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 48, 187, 157), // Choisis une couleur (ex : deepPurple)
      ),
    ),
    initialRoute: '/login', // Redirige initialement vers LoginPage
    routes: {
      '/login': (context) => const LoginPage(),
      '/statistics': (context) => StatisticsPage(userId: ModalRoute.of(context)!.settings.arguments as String),
      '/settings': (context) => SettingsPage(userId: ModalRoute.of(context)!.settings.arguments as String),
      '/addWeatherLocation': (context) => AddWeatherLocationPage(userId: ModalRoute.of(context)!.settings.arguments as String),
    },
    onGenerateRoute: (settings) {
      if (settings.name == '/home') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => HomePage(userId: userId),
        );
      } else if (settings.name == '/statistics') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => StatisticsPage(userId: userId),
        );
      } else if (settings.name == '/settings') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => SettingsPage(userId: userId),
        );
      } else if (settings.name == '/addWeatherLocation') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AddWeatherLocationPage(userId: userId),
        );
      } else if (settings.name == '/addParcel') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AddParcelPage(userId: userId),
        );
      } else if (settings.name == '/addSensor') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AddSensorPage(userId: userId),
        );
      } else if (settings.name == '/addAutomate') {
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AddAutomatePage(userId: userId),
        );
      }
      return null;
    },
  );
}

}

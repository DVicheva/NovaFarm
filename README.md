🌱 NovaFarm - Application Flutter

NovaFarm est une application Flutter permettant de gérer des parcelles agricoles avec des capteurs d'humidité et une IA connectée à Firebase.

🛠️ Prérequis

Avant de commencer, assure-toi d'avoir les outils suivants installés sur ton système :

Flutter SDK

📌 Installation Flutter

Vérifie l'installation avec :

flutter doctor

Dart SDK (inclus avec Flutter)

Vérifie l’installation avec :

dart --version

Android Studio ou VS Code (recommandé)

📌 Installation VS Code

📌 Installation Android Studio

Git

📌 Installation Git

Vérifie l’installation avec :

git --version

🚀 Installation du projet

1️⃣ Cloner le projet depuis GitHub

Ouvre un terminal et exécute :

 git clone https://github.com/ton-utilisateur/ton-repo.git
 cd ton-repo

Si tu veux contribuer au projet, fork-le et clone-le depuis ton repo :

 git clone https://github.com/ton-utilisateur/nova_farm.git
 cd nova_farm

2️⃣ Installer les dépendances

Exécute la commande suivante pour télécharger toutes les dépendances Flutter :

 flutter pub get

3️⃣ Configuration Firebase 🔥

Créer un projet Firebase sur Firebase Console

Ajouter une application Flutter dans Firebase

Télécharger le fichier google-services.json (pour Android) et GoogleService-Info.plist (pour iOS)

Placer le fichier :

Android : android/app/google-services.json

iOS : ios/Runner/GoogleService-Info.plist

Activer Firestore, Authentication et Realtime Database dans Firebase

4️⃣ Lancer l'application

Utilise la commande suivante pour exécuter l'application sur un simulateur ou un appareil physique :

 flutter run

Si tu veux exécuter l’application sur un appareil spécifique :

 flutter devices  # Liste les appareils connectés
 flutter run -d <device_id>

💡 Développement avec VS Code

Si tu utilises VS Code, installe les extensions Flutter/Dart :

Flutter (par Google)

Dart (par Dart Code)

Ajoute le débogage avec :

code .

🌍 Utilisation de GitHub

1️⃣ Initialiser GitHub dans ton projet

git init
git remote add origin https://github.com/ton-utilisateur/ton-repo.git
git branch -M main
git pull origin main

2️⃣ Envoyer des modifications (commit & push)

git add .
git commit -m "Initial commit"
git push origin main

3️⃣ Mettre à jour ton code localement

git pull origin main

📜 License

MIT License © 2024 NovaFarm

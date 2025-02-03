# 📌 NovaFarm - Application Flutter

NovaFarm est une application mobile développée avec **Flutter** et **Firebase** permettant la gestion et l'automatisation de l'irrigation agricole à l'aide de capteurs intelligents.

## 🚀 Installation et Configuration

### 1️⃣ Prérequis
Avant de commencer, assurez-vous d'avoir installé :

- [Flutter](https://flutter.dev/docs/get-started/install) (version recommandée : 3.x.x)
- [Dart](https://dart.dev/get-dart) (inclus avec Flutter)
- [Visual Studio Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio)
- [Git](https://git-scm.com/)
- Un émulateur Android/iOS ou un appareil physique

### 2️⃣ Cloner le projet

```bash
# Ouvrez un terminal et exécutez la commande :
git clone https://github.com/votre-utilisateur/nova_farm.git
cd nova_farm
```

### 3️⃣ Installation des dépendances

```bash
flutter pub get
```

### 4️⃣ Configuration Firebase (à ne pas faire, c'est déjà fait !) 
1. Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com/).
2. Activez **Firestore Database** et **Authentication**.
3. Téléchargez le fichier `google-services.json` (Android) ou `GoogleService-Info.plist` (iOS) et placez-le dans le dossier approprié :
   - `android/app/` pour Android
   - `ios/Runner/` pour iOS
4. Activez l'authentification avec l'email et les fournisseurs de votre choix.

### 5️⃣ Lancer l'application

```bash
flutter run
```

> **Note :** Si vous souhaitez exécuter l'application sur iOS, assurez-vous d'avoir Xcode installé et configuré.

## 🌱 Développement

### Structure du projet
```
📂 nova_farm
 ┣ 📂 lib
 ┃ ┣ 📂 pages       # Pages principales (Home, Statistiques, Paramètres...)
 ┃ ┣ 📂 widgets     # Composants réutilisables
 ┃ ┣ 📂 services    # Gestion des services (Firebase, API...)
 ┃ ┗ main.dart      # Point d'entrée de l'application
 ┣ 📂 android       # Fichiers Android
 ┣ 📂 ios           # Fichiers iOS
 ┣ 📂 assets        # Images et fichiers statiques
 ┣ pubspec.yaml     # Dépendances Flutter
 ┗ README.md        # Documentation
```

### 🔥 Déploiement sur GitHub

```bash
# Initialiser le dépôt
git init

git add .
git commit -m "Initial commit"

git branch -M main
git remote add origin https://github.com/votre-utilisateur/nova_farm.git
git push -u origin main
```
## 📄 Licence
Ce projet est sous licence **MIT**.

## 📧 Contact
Pour toute question ou amélioration, contactez-moi à **project@novafarm.com**.

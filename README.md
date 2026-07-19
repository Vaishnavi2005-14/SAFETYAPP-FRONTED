# Shtree Kavach - Safety App Frontend

Shtree Kavach is a premium, offline-first Flutter-based safety application designed to provide immediate assistance to women in emergency situations. It features a modern, dark-indigo/pink themed UI with interactive cards, background shake panic detection, custom fake call simulation, emergency contact cloud syncing, and Google Sign-In.

---

## 1. Features & Capabilities

- **Panics & SOS Triggers**: Triggers standard emergency calls and constructs an SOS SMS message embedded with the user's high-accuracy GPS coordinates.
- **Background Shake Detection**: Accelerometer sensor stream listener captures physical shake forces and triggers the SOS automatically even when the screen is locked.
- **Fake Call Simulation**: Plays a loopable ringtone (`ringtone.ogg`) and emulates a call interface to help users safely exit uncomfortable situations.
- **Google Sign-In**: Traditional password-based registration along with fast Google Account authentication.
- **Offline-First Synchronization**: Caches all profile edits and guardian contacts locally in SharedPreferences before synchronizing with the cloud database.

---

## 2. Tech Stack & Key Libraries

- **flutter**: SDK for cross-platform UI and components.
- **google_sign_in**: Allows user authentication via Google Accounts.
- **geolocator**: Queries high-accuracy GPS latitude and longitude coordinates.
- **url_launcher**: Opens dialer and mapping URLs.
- **permission_handler**: Manages runtime checks and permission requests for GPS, contacts, and SMS.
- **shared_preferences**: Local disk cache storing contacts, active JWT, profile details, and sensitivity parameters.
- **audioplayers**: Plays alert sirens and call ringtones.
- **google_fonts**: Loads clean modern typography.
- **sensors_plus**: Listens to accelerometer streams for physics-based shake triggers.
- **http**: Communicates with the Express and MongoDB Atlas cloud backend.

---

## 3. Directory Structure

```
lib/
│
├── main.dart                 # App configuration, theme, and route initialization
│
├── screens/
│   ├── splash_screen.dart    # Logo animation, particle physics loader, and auth check
│   ├── login_screen.dart     # Email form and Google login interface
│   ├── signup_screen.dart    # Account creation card and Google signup interface
│   ├── home_screen.dart      # Main dashboard, shake detection, and SOS trigger
│   ├── contacts_screen.dart  # Guardian contacts manager and official helpline directory
│   ├── profile_screen.dart   # Profile settings card, sensitivity toggles, and logout
│   └── fake_call_screen.dart # Call dialer UI and audio player simulation
│
└── services/
    └── api_service.dart      # REST API handler with SharedPreferences offline storage
```

---

## 4. Setup & Running

### 1. Backend Endpoint Setup
Before running the app, update the `baseUrl` inside `lib/services/api_service.dart` to point to your backend deployed on Railway:
```dart
static const String baseUrl = 'https://your-backend.up.railway.app/api';
```

### 2. Execution
Run the following commands to install dependencies and run the application:
```bash
flutter pub get
flutter run
```

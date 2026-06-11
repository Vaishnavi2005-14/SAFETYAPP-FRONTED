# Shtree Kavach - Safety App Frontend

Shtree Kavach is a premium Flutter-based safety application designed to provide immediate assistance to women in emergency situations. It features a modern, dark-indigo/pink themed UI with interactive cards, real-time location mapping, background shake detection, audio call triggers, and full backend integration with local caching.

---

## 1. Tech Stack & Key Libraries

The application is built using the following Flutter packages:

- **flutter**: SDK for UI design and core logic.
- **geolocator**: To fetch the high-accuracy latitude and longitude of the user during emergencies.
- **url_launcher**: To trigger the phone dialer for custom emergency contacts or police/women helplines.
- **permission_handler**: To check and request GPS location and SMS sending permissions.
- **shared_preferences**: Local disk cache storing active contacts, profile data, and shake sensitivity configuration to support full offline-first functionality.
- **audioplayers**: Play alert sounds for emergencies and ringtones for the fake call feature.
- **google_fonts**: Load the premium "Outfit" typeface.
- **sensors_plus**: Listen to the physical accelerometer data in the background to detect shake forces.
- **http**: Handle network communication with the MongoDB backend.

---

## 2. Directory Structure

```
lib/
│
├── main.dart                 # App configurations, themes, and route declarations
│
├── screens/
│   ├── splash_screen.dart    # Loader animation, background particle effects, and login check
│   ├── login_screen.dart     # User authentication form
│   ├── signup_screen.dart    # Account creation form
│   ├── home_screen.dart      # Dashboard, SMS trigger, and shake sensor listener
│   ├── contacts_screen.dart  # Guardian contacts and government helplines directory
│   ├── profile_screen.dart   # Profile settings, shake sensitivity controller, and logout
│   └── fake_call_screen.dart # Call dialer and ringtone player simulation
│
└── services/
    └── api_service.dart      # HTTP API service layer with local storage caching
```

---

## 3. Detailed Screen Explanations

### 1. Splash Screen (splash_screen.dart)
- **Visuals**: A rotating logo accompanied by pulsating custom particle physics and a neon shadow title using Flutter's CustomPainter.
- **Logic**: Executes a timer for 5 seconds. In the background, it checks the local cache (SharedPreferences) for a JSON Web Token (jwt_token). If found, it routes to /home; otherwise, it redirects to /login.

### 2. Login Screen (login_screen.dart)
- **Visuals**: Dark glassmorphic email and password inputs with custom pink glowing borders.
- **Logic**: Validates inputs. Calls ApiService.login(). If successful, saves the JWT token to local disk, populates the cached user details, and opens /home.

### 3. Signup Screen (signup_screen.dart)
- **Visuals**: Clean registration card.
- **Logic**: Performs strict validation checks. Calls ApiService.signup() and launches the main dashboard.

### 4. Home Screen (home_screen.dart)
- **Visuals**: Modern bottom navigation bar with fluid icon transitions.
- **Logic**:
  - Initializes a background accelerometer stream listener. If the accelerometer force exceeds the defined sensitivity threshold, it triggers SOS.
  - Fetching Location: Uses Geolocator to query GPS coordinates, generates a Google Maps hyperlink, and forms an SOS distress message.
  - Sending SOS: Triggers the native SMS builder pre-loaded with all guardians' phone numbers and the message.

### 5. Contacts Screen (contacts_screen.dart)
- **Visuals**: Tabbed layout dividing personal guardian contacts (pink accents) and official helplines (cyan accents).
- **Logic**:
  - Automatically loads contacts from local storage on launch.
  - Triggers an asynchronous synchronization request to the backend. If new contacts are found on the server, the local view is refreshed.
  - Users can dial contacts directly or remove/add guardians.

### 6. Profile Screen (profile_screen.dart)
- **Visuals**: Informational cards outlining Aadhaar number, custom message, and shake settings.
- **Logic**:
  - Users can configure their custom message and toggle shake detection on/off or change sensitivity (Low, Medium, High).
  - Pressing "Logout" clears the token, deletes cache keys, and returns the user to the login screen.

### 7. Fake Call Screen (fake_call_screen.dart)
- **Visuals**: Emulates a real caller interface.
- **Logic**: Plays a looping ringtone (ringtone.ogg) using audioplayers. If the user slides to accept, it shows an active call timer; if declined, it closes.

---

## 4. Sync & Offline-First Strategy

To guarantee maximum reliability:
1. **Reads**: The app reads profile configurations and emergency contacts directly from SharedPreferences locally. This ensures zero latency and offline availability.
2. **Writes**: When saving profiles or contacts, the app updates the local cache first. It then sends an asynchronous HTTP request to the Express/MongoDB backend to synchronize the cloud database.
3. **Restoration**: If the app is uninstalled and reinstalled, logging back in retrieves all profile data and contacts from MongoDB and writes them back into local storage cache.

<p align="center">
  <img src="assets/branding/banner.png" alt="EcoCycle Banner" width="100%">
</p>

<h1>
  EcoCycle
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  </a>
  +
  <a href="https://google.com">
    <img src="https://img.shields.io/badge/Firebase-DD2C00?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase">
  </a>
</h1>





EcoCycle is a cross-platform Flutter and Dart mobile application developed for the ITS Web & Mobile App Developer final project. It helps citizens discover recycling points in the Turin area and explore a demonstrative smart waste management experience.

## Features

- Firebase email/password and Google authentication, password recovery and onboarding.
- Interactive OpenStreetMap map and API-backed list, with search, filters, marker grouping, optional GPS, point details, nearby alternatives and external walking directions.
- Deterministic simulated container telemetry and locally saved favorites.
- XP progression, self-declared recycling activities, a mission and demonstrative rewards.
- Local reports with optional photos and location, history and deletion.
- Profile editing, a locally stored custom avatar, persistent Light/Dark themes, launcher icon, native splash and animated loading.

## Getting started

Use Flutter with a Dart SDK compatible with `pubspec.yaml` (`^3.13.4`), Android SDK and an Android device or emulator with Google Play services and internet access. Keep the existing Firebase configuration and Android application ID `com.example.ecocycle`.

```bash
flutter pub get
flutter run
```

Google sign-in is enabled by default in the configured Android build. For another development computer or signing certificate, register its SHA-1 and SHA-256 in the existing Firebase project, enable Google authentication and refresh `android/app/google-services.json` if necessary. See [integration notes](docs/integrations.md). Do not commit private signing keys, passwords, service-account credentials or OAuth client secrets.

## REST API

EcoCycle uses `http` to fetch real recycling records from the Overpass API:

- Base URL: `https://ovp.dresel.systems`
- Endpoint: `GET /api/interpreter`
- Query parameter: `data` (Overpass QL); no API key.

```overpass
[out:json][timeout:15];
nwr["amenity"="recycling"](45.00,7.58,45.14,7.77);
out center;
```

The JSON response contains OSM element IDs, coordinates and tags. These records feed the map, list, previews and details. The bounding box covers Turin and nearby areas, not the official municipal boundary. Loading, HTTP timeout, errors, empty states and retry are handled. Missing OSM metadata is not invented. Basemap tiles are provided by OpenStreetMap, separately from the Overpass data request.

## Real and demonstrative data

| Real data | Demonstrative or local data |
| --- | --- |
| Firebase account identity | Onboarding preferences, favorites, custom avatar |
| OSM point IDs, coordinates and available material/address tags | Simulated fill level, operational status, temperature, capacity, weight and gas readings |
| Device location (with permission) | Self-declared recycling, XP, missions and reward redemption |
| User-selected photos | Reports stored on the device, not sent to a waste operator |

No real sensors, AI, municipal reporting backend or commercial reward service are connected. Local records are scoped to the Firebase UID; they are not synchronized across devices and may be lost when app data is cleared. The theme preference is device-wide.

## Project structure

```text
lib/
  main.dart       # initialization and theme selection
  models/         # recycling points and simulated telemetry
  services/       # REST, authentication, local persistence and XP
  screens/        # authentication, onboarding, map, rewards, reports, profile
  theme/          # centralized Light/Dark themes
  widgets/        # shared UI and animated loader
assets/           # logo and branding assets
test/             # model, service, XP and widget tests
```

## Verification and builds

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

The APK is normally created at `build/app/outputs/flutter-apk/app-release.apk`. The signing certificate of the actual APK must match the Firebase OAuth configuration for Google sign-in. Test the installed APK before submission. 


## Supported platforms

| Platform | Package | Installation | Validation |
| --- | --- | --- | --- |
| Android | APK | Direct installation | Android emulator |
| iOS | IPA | AltStore Classic | iPhone 12 Pro |

### iOS installation

1. Download the unsigned IPA from GitHub Releases.
2. Install and configure AltStore Classic using AltServer.
3. Open AltStore and select the IPA from the My Apps section.
4. Sign and install the application using your Apple Account.

The iOS application is compiled using Codemagic on macOS. A free Apple Account requires the application to be refreshed every seven days. No paid Apple Developer membership is required for personal sideloading.

The application is not distributed through the Apple App Store.


## Credits and documentation

- Map data and tiles: [OpenStreetMap contributors](https://www.openstreetmap.org/copyright); [tile usage policy](https://operations.osmfoundation.org/policies/tiles/).
- Recycling data: Overpass API; public endpoints may be temporarily unavailable.
- Identity: Firebase Authentication and Google Sign-In.
- [Integration notes](docs/integrations.md)

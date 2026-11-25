# Integration notes

## Overpass and OpenStreetMap

`RecyclingService` performs an HTTP GET at `https://ovp.dresel.systems/api/interpreter`, with URL-encoded `data` containing the query:

```overpass
[out:json][timeout:15];
nwr["amenity"="recycling"](45.00,7.58,45.14,7.77);
out center;
```

No API key is required. The client timeout is 25 seconds. Node coordinates come from `lat`/`lon`; ways and relations use `center`. `RecyclingPoint` retains the element type, ID, coordinates and tags; materials are inferred from explicit `recycling:* = yes` tags and translated where known. The REST result is shared by the map, list, preview, detail and alternative selection. The request covers a fixed demonstration area and is not repeated on every pan or zoom.

The basemap is rendered with `flutter_map` using `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. Attribution is displayed. A local color filter changes the appearance of the standard tiles in Dark Mode; this is not a dedicated dark tile provider. Marker grouping is an approximate zoom-dependent grid, not a dedicated spatial clustering engine. At high zoom, co-located points can still overlap. Public API and tile availability are not guaranteed. Respect the OSM tile policy; do not prefetch or bulk-download tiles. No reverse geocoding is performed.

## Authentication

The existing Firebase project supplies email/password authentication, password recovery, Google identity and session state. Google Sign-In is enabled by default for the configured Android build. The application ID must remain `com.example.ecocycle` unless Firebase/OAuth is reconfigured.

On Windows, if Gradle cannot find Java, set `JAVA_HOME` to the actual installed JDK (Android Studio's `jbr` is an option). From the project root:

```powershell
cd android
.\gradlew signingReport
cd ..
```

Register the appropriate signing certificate's SHA-1 and SHA-256 in Firebase project settings. Enable Google in Authentication, select the project support email, and download the matching Android `google-services.json` again. Check for an Android OAuth client (`client_type: 1`) with the correct package and certificate hash, and a web OAuth client (`client_type: 3`). Use a Google Play-capable device or emulator. Do not include any OAuth client secret or private keystore in Git. Apple authentication remains optional/configuration-gated and is not verified; Facebook is out of scope.

## Telemetry and alternatives

The stable OSM identifier seeds demonstrative telemetry; it does not come from sensors. Fill statuses are normal (0–69%), nearly full (70–89%) and full (90–100%); unavailable and maintenance override fill status. Capacity, estimated occupied/residual volume, estimated weight, temperature and gas are synthetic. Collection centres without container telemetry are distinguished from containers. Alternative containers share at least one material, have a simulated available/nearly full status and are within 3 km in straight-line distance of the selected point; up to three are shown. External directions use Google Maps URLs, not a routing API.

## Local persistence and XP

`LocalStore` uses UID-scoped `SharedPreferencesAsync` records; local report and profile images are stored in app-private documents folders per UID. The theme is device-wide. Records are not cloud-synchronized. No user password is stored manually.

`XpService` calculates progression from recorded activity: onboarding +100 once; first self-declared recycling day +50, later days +20; one report credit of +50 per distinct day; mission +100 after three distinct recycling days. Deleting a report retains its earned date, not its deleted description, photo or coordinates. Each level requires 500 total earned XP; spending XP affects the available balance but not the level. Legacy redemptions from the former fixed balance are retained separately. Rewards are demonstrative, not commercial claims. Daily limits are local demonstration rules, not anti-fraud security.

## Acceptance checks

| Requirement from the project brief | Implementation evidence |
| --- | --- |
| Real REST API via HTTP | `RecyclingService` and Overpass |
| At least three connected screens | `AuthGate`, `HomeShell`, detail routes |
| API-driven list/detail | `RecyclingPoint` map/list/preview/detail |
| Loading and network error handling | FutureBuilder, timeout, retry and loading animation |
| Clear code and separation | models, services, screens, theme and widgets |
| Light and Dark themes | shared ThemeData and persisted theme mode |
| README and 5–8 minute demo | root README.md and DEMO.md |

Before submission, run the analyzer and tests, install the APK, and check email and Google auth, loading/error states, map/filter/detail/navigation, favorites, XP/redemption, reports, avatar isolation, theme and logout. The student has reported successful emulator checks; this document does not certify the final APK or the final test run. The original official assignment file was not independently available for this documentation revision; compare the checklist with the actual teacher brief.

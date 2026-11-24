# Integration and acceptance notes

## Source audit

Base: `SCodreanu/ecocycle-app` default branch, latest observed commit `313e06753e7b18b6a9cdf0c8bb28cf6b58be3a24` (Add user geolocation). Source files were fetched through the GitHub connector. The existing local checkout was not accessible; no remote commit or push was performed. The overlay contains only targeted replacement/new files. The original Firebase configuration, Android manifest, Gradle files and lockfile are not included or overwritten.

Reviewed the supplied Figma PDF (mobile wireframe/auth/onboarding/map/rewards/detail/report/profile/error pages, especially 1, 10, 15, 17–18, 25–26, 38–42, 54–62, 66 and 69); the React ZIP's map, brand CSS and authentication; the PNG/SVG logo; the course materials (especially Day 8–12 and 15); and the final project brief. The official assignment file and original slide presentation were not independently retrieved. Requirements supplied in the project brief are the basis of the checklist. React PHP/MySQL, synthetic coordinates and administrative screens were not copied.

Design decisions: use original transparent PNG, dark-green brand palette from React and Figma, Material 3 central themes, two-stage registration without unnecessary DOB/country, simplified onboarding without unsupported notifications, fixed Turin query, status telemetry only for known containers, explicit local-only reports and rewards. Use Android as primary target. Standard OSM raster tiles remain light even in the dark theme.

## Integration references

- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/auth/flutter/start
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/shared_preferences
- https://pub.dev/packages/image_picker
- https://pub.dev/packages/path_provider
- https://pub.dev/packages/url_launcher
- https://pub.dev/packages/flutter_map
- https://pub.dev/packages/geolocator
- https://operations.osmfoundation.org/policies/tiles/
- https://www.openstreetmap.org/copyright

## Acceptance checklist (run on the Android checkout)

| Requirement | Evidence in the supplied source | Runtime verification |
| --- | --- | --- |
| Real REST via http | RecyclingService GET with existing Overpass query | Pending |
| Three or more screens | Auth + map/list/detail + rewards + reports + profile + onboarding | Pending |
| API-backed list/detail | RecyclingPoint list and detail | Pending |
| Loading, network failure, empty, retry | FutureBuilder and test cases | Pending |
| Navigation | AuthGate, HomeShell and modal/detail routes | Pending |
| Light/dark | Shared ThemeData, ThemeMode, local preference | Pending |
| Location cases | Android permissions preserved, explicit request/status and settings | Pending |
| Form validation and feedback | Auth and report forms | Pending |
| Local data by user | UID keys and photo folders | Pending |
| Repo/compilable submission | Overlay must be applied to original checkout; build pending | Pending |
| README and 5–8 min demo | README.md and DEMO.md supplied | Documents authored |

## Limits and test plan

- No actual Firebase project console access, OAuth configuration, dependency resolution, Android build, device or emulator execution in this environment.
- Confirm all packages resolve together and run `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug`. Fix any SDK/version issues before release.
- Test auth registration (including duplicate email and display name update), wrong password, offline, reset email, user session after restart and logout. Social login is configuration gated; Google and Apple paths are unverified. Facebook is not implemented.
- Test every route at small and large Android sizes, keyboard open, long names/materials, map gestures, list toggle, marker preview, detail, point-linked reports, no results, API errors, tile errors, and permission state recovery. No visual validation of the Flutter output has been performed.
- Verify photo selection/cancellation, camera capture, durable image path after restart, local history, two different Firebase accounts and no cross-account data leakage. Test storage failure and rapid duplicate taps. The app has no external reporting or commercial redemptions.
- The fixed Turin query avoids continuous or unbounded public API calls; outside Turin, the user marker can be far from the loaded points. This does not imply global point coverage.
- Verify the tile cache and network headers against the current public OSM tile policy before wider deployment. Do not prefetch or bulk-download.
- Accessibility, contrast, tile caching behavior, Android activity restoration, persistence tests and all real-device behavior require follow-up. This is a source update, not a verified release APK.

# Google Maps Platform setup

The Flutter package and Android native wiring are already present. The Android
build reads `MAPS_API_KEY` from the ignored `android/local.properties` file. If
the property is absent, the APK still compiles, but Google Maps tiles will not
load until a valid key is supplied.

`google-services.json` configures Firebase. It does **not** automatically
configure the Google Maps SDK key used by `google_maps_flutter`.

## 1. Enable Google Maps Platform

1. Open [Google Cloud Console](https://console.cloud.google.com/) and select the
   Google Cloud project connected to this app's Firebase project.
2. Attach a billing account to that project. Google Maps Platform APIs require
   billing even when usage remains within applicable no-cost allowances.
3. Open **APIs & Services > Library** and enable **Maps SDK for Android**.

For destination and route planning, also enable these backend APIs:

- **Routes API** for route alternatives, encoded polylines, distance, and ETA.
- **Places API (New)** for pickup/destination search and place IDs.
- **Geocoding API** only if the backend needs address/coordinate conversion that
  is not already covered by the app's device geocoder or Places results.

## 2. Create the Android map key

Create a dedicated key rather than reusing a Firebase or backend key:

1. Open **APIs & Services > Credentials > Create credentials > API key**.
2. Edit the new key and name it something clear, such as
   `Multi Service Android Maps`.
3. Under **Application restrictions**, choose **Android apps**.
4. Add an Android application with:
   - Package name: `com.kisha.multiservice`
   - SHA-1 certificate fingerprint: the SHA-1 for the certificate signing the
     build being installed.
5. Under **API restrictions**, choose **Restrict key**, select only
   **Maps SDK for Android**, and save.

Get the local debug SHA-1 on Windows with:

```powershell
Set-Location android
.\gradlew.bat signingReport
```

Use the `SHA1` shown for the `debug` variant. Before distributing the app, add
the release signing SHA-1 as another Android application restriction. For a
Google Play release, also add the **Play App Signing** SHA-1 shown in Play
Console; it can differ from the upload-key SHA-1.

For the debug keystore currently installed on this development computer, the
validated restriction pair is:

```text
Package: com.kisha.multiservice
SHA-1:   4E:B6:A0:E7:76:FB:59:40:33:37:82:29:95:95:32:E3:74:F9:68:36
```

Run `signingReport` again if the debug keystore is replaced or the project is
built on another computer, because that SHA-1 can change.

## 3. Keep the key local

Copy the example setting into the existing `android/local.properties` file and
replace the placeholder:

```properties
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

Do not remove the existing `sdk.dir` or `flutter.sdk` lines. The real
`android/local.properties` file is ignored by version control; only
`android/local.properties.example` is a safe template.

Stop and rerun the app after changing the key. A normal rebuild is sufficient:

```powershell
flutter run
```

If the map canvas appears but tiles stay blank, inspect the Android logs for
`Authorization failure` and verify all three values: enabled API, package name,
and signing SHA-1.

When no valid Android Maps key is present, the app automatically uses its
code-drawn route preview instead of opening a blank native map.

## 4. Use separate server credentials for routes and places

Do not place a Routes API or Places API web-service key in Flutter source,
`--dart-define`, or the APK. Mobile apps can be inspected, so a web-service key
embedded in the app cannot be kept secret.

The production design should be:

1. Flutter sends the typed destination and pickup coordinate to this project's
   backend at `POST /api/v1/maps/places/resolve`.
2. The backend resolves that text with Places API (New), then Flutter sends the
   resulting coordinates to `POST /api/v1/maps/routes`.
3. The backend calls Routes API without exposing either server credential.
4. Restrict the key to the production server's fixed outbound IP addresses and
   restrict its APIs to only **Routes API** and **Places API (New)** (plus
   **Geocoding API** only if actually used).
5. The backend returns route options containing distance, ETA, and encoded
   polylines; Flutter draws them with `google_maps_flutter`.

Set these only in `backend/multi_service_backend/.env`:

```properties
GOOGLE_ROUTES_API_KEY=YOUR_SERVER_KEY
GOOGLE_PLACES_API_KEY=YOUR_SERVER_KEY
```

The same restricted server key can be used for both values, or you can create
two server keys. The Android Maps key must remain separate.

Routes API can return a default route and up to three alternatives when
`computeAlternativeRoutes` is enabled. Google supplies distance and travel time;
the app/backend's fare rules calculate the displayed ride price.

Live driver tracking does not use the Maps key as a tracking service. Driver GPS
updates should travel through the backend/WebSocket layer; the Android Maps SDK
only renders the driver's latest position and selected route.

## iOS status

This repository is wired for Android only in this change. Its iOS directory has
no `Podfile`, while Flutter's generated Swift package currently contains no
plugin dependencies, so adding `import GoogleMaps` to `AppDelegate.swift` would
be unsafe without first repairing and validating the iOS dependency setup on
macOS. When iOS support is prepared, create a **separate** Maps SDK for iOS key,
restrict it to the final iOS bundle identifier, store it outside source control,
and provide it to `GMSServices.provideAPIKey` during app startup.

## Official references

- [Set up Google Maps for Flutter](https://developers.google.com/maps/flutter-package/config)
- [Google Maps Platform API security guidance](https://developers.google.com/maps/api-security-best-practices)
- [Routes API alternative routes](https://developers.google.com/maps/documentation/routes/alternative-routes)

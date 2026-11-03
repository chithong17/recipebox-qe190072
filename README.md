# RecipeBox

Flutter Android practical exam application by Phan Chi Thông, QE190072.

## Run

Use Flutter 3.44.5 / Dart 3.12.2 or compatible newer SDK, Android SDK and Java 17+.

```sh
flutter pub get
flutter run
flutter build apk --release
```

Set up the local Firebase client configuration before running the app. From the project root, run `flutterfire configure --project=recipebox-qe190072 --platforms=android` to generate `lib/firebase_options.dart`. Place the Android configuration downloaded from Firebase Console at `android/app/google-services.json`. Both files are ignored by Git. Enable Email/Password Authentication, create the default Firestore database, and deploy `firestore.rules` for the Firebase project.

## Features

Home, Firebase registration/login, private realtime recipes, validated Add/Edit forms, persistent favorites, combined category/difficulty/favorite/search filters, live summary, details and confirmed deletion. Sorting is cooking time ascending then case-insensitive name. The warm green design follows the supplied design specification and supports system dark mode.

## Database

Only the `recipes` collection is used. Optional empty servings are omitted; notes default to an empty string. Names are unique per user using the canonical document ID:

`uid + '_' + base64(UTF8(trim(name).toLowerCase()))`

Replace `/` with `_` and `+` with `-`; retain `=` padding. Security Rules independently calculate and enforce this ID, ownership, allowed fields, types and all value ranges. Renames use a transaction that checks the target and moves the document, keeping its creation timestamp and favorite. Existing documents cannot change their canonical name in place. Queries must include `where('userId', isEqualTo: currentUid)`.

```sh
firebase deploy --only firestore:rules --project recipebox-qe190072
flutter analyze
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d DEVICE_ID
```

The device acceptance test uses real Firebase client SDK calls and captures actual app screenshots. It creates test-only accounts and recipes in this exam project.

The release uses Android debug signing for installation during grading; it is a release-mode APK, not a Google Play publication build.

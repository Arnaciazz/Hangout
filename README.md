# Hangout

Deciding where to go, made easy. A crew swipes on the same restaurants or
places, and the one most of them want wins. The host reveals it, and there's
a way to book, get directions, and split the bill over UPI. Solo users swipe
to explore and keep the places they liked.

Android only, built for India (₹, UPI, Dineout, EazyDiner). Flutter +
Supabase + Google Places + Firebase Cloud Messaging.

- Product context: [PRODUCT.md](PRODUCT.md)
- Server setup (database, push): [supabase/README.md](supabase/README.md)

## Run it

```bash
flutter pub get
flutter run
```

`lib/config/app_config.dart` holds the Supabase URL and anon key and the
Google API key. Strings are generated from `lib/l10n/app_en.arb` on every
build (`flutter gen-l10n` does it by hand).

## Before the first Play Store build

The package id is **`app.hangout.android`**. Firebase and Google Cloud still
know the app by the old placeholder id, so these console steps are needed
first. **The Android build fails until step 1 is done.**

1. **Firebase:** Project settings → Add app → Android, package
   `app.hangout.android`. Download the new `google-services.json` into
   `android/app/`, replacing the old one.
2. **Google Sign-In:** in Google Cloud Console → APIs & Services →
   Credentials, create an **Android** OAuth client for `app.hangout.android`
   with your debug and release SHA-1 fingerprints (`./gradlew signingReport`
   in `android/` prints them). Keep the existing Web client; the app uses it
   as `serverClientId`.
3. **Maps / Places key:** if the API key is restricted to Android apps, add
   `app.hangout.android` with the same SHA-1s.
4. **Release signing:** create an upload keystore and
   `android/key.properties` (both are git-ignored):

   ```properties
   storeFile=C:/path/to/upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without it, release builds are signed with the debug key, which the Play
   Store rejects.
5. **Legal links:** publish a privacy policy and terms, then set both URLs in
   `lib/config/legal_links.dart`. The sign-in screen shows the agreement
   line only once they're set. The Play Store requires a privacy policy for
   an app that handles phone numbers and location.

## Tests

```bash
flutter analyze
flutter test
```

Layout tests run the screens at 320 px with large text to catch overflows.
Visual previews of the screens render to `test/preview/` without a device:

```bash
flutter test --run-skipped --tags preview --update-goldens test/golden_preview_test.dart
```

## Layout

```
lib/
  main.dart              app, auth gate, four-tab shell
  config/                keys, legal links
  l10n/                  app_en.arb (every user-facing string) + generated code
  models/                Place, Group
  services/              Supabase + Places access: sessions, crews, bills,
                         history, profile, push notifications
  screens/               one file per screen
  widgets/               the design system's components
  theme/                 colour, type, spacing, motion tokens
  utils/                 money (paise, ₹, UPI links), dates, external links
  dev/fixtures.dart      placeholder data for tests and the design gallery
supabase/
  schema.sql, 002_complete_app.sql, 003_lock_down_functions.sql
  functions/notify/      push notifications
```

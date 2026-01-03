# K-Book Flutter App

Flutter app for the K-Book backend.

## Requirements

- Flutter 3.35+
- Backend running on `http://localhost:8080`

## Configure API base URL

Edit `lib/core/config/app_config.dart`:

- Android emulator: use `http://10.0.2.2:8080`
- iOS simulator: use `http://localhost:8080`
- Physical device: use your machine IP, e.g. `http://192.168.1.50:8080`

## Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

# Sports Booking App

This repository contains a Flutter client and a Django backend.
The quickest way to try it is with Docker and Flutter:

```bash
# 1. start backend services
docker compose up -d

# 2. apply migrations (first run only)
docker compose exec web python manage.py migrate --noinput

# 3. get Flutter packages
flutter pub get

# 4. run the app on an emulator/device
flutter run
```
The backend exposes a simple auth API supporting email/password and Google login.
After signing up or using Google the app stores JWT tokens securely and the
profile page shows your account email.

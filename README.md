# Sports Booking App

This repository contains a Flutter client and a Django backend.
The quickest way to try it is with Docker and Flutter:

```bash
# 1. copy environment file and start services
cp .env.example .env
docker compose up -d --build

# 2. apply migrations (first run only)
# note manage.py lives in the backend folder inside the container
docker compose exec web python backend/manage.py migrate --noinput

# 3. verify the backend is running
curl -f http://localhost:8000/healthz

# 4. get Flutter packages
flutter pub get

# 5. run the app on an emulator/device
flutter run
```
If testing on the Android emulator, ensure `ALLOWED_HOSTS` in `.env` includes
`10.0.2.2` so Django accepts requests from the emulator.
The backend exposes a simple auth API supporting email/password and Google login.
After signing up or using Google the app stores JWT tokens securely and the
profile page shows your account email.

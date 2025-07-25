# Sports Booking App

This project contains a Flutter client and a Django backend.
The quickest way to try it is with Docker and Flutter:

```bash
# 1. copy environment file and start services
cp .env.example .env
# add your Stripe keys in .env
docker compose up -d --build

# 2. apply migrations (first run only)
# note manage.py lives in the backend folder inside the container
docker compose exec web python backend/manage.py migrate --noinput

# 3. optional: load demo sports and facilities
docker compose exec web python backend/manage.py seed_taxonomy
docker compose exec web python backend/manage.py seed_sports
docker compose exec web python backend/manage.py seed_facilities

# 4. collect static files
docker compose exec web python backend/manage.py collectstatic --noinput

# 5. verify the backend is running
curl http://localhost:8000/healthz

# 6. get Flutter packages
flutter pub get

# 7. run the app on an emulator/device
flutter run

```

The Docker image runs `collectstatic` during build and serves the compiled
assets with [WhiteNoise](https://whitenoise.evans.io/) so the Django admin loads
its CSS correctly when deployed.

The `.env` file must define `API_BASE_URL` so the Flutter app knows where the
backend is. It should also include the Stripe keys used by the payment flow.
When testing on the Android emulator the correct value for `API_BASE_URL` is
`http://10.0.2.2:8000/api`.
`initApiClient` automatically appends a trailing slash so either form
(`http://10.0.2.2:8000/api` or `http://10.0.2.2:8000/api/`) works.

If running the backend without Docker, install dependencies with
`pip install -r requirements.txt` and apply migrations using `python manage.py migrate`.
GeoDjango requires the GDAL library. On most systems it is easiest to use the
Docker environment above. If you want to run locally ensure `gdal` and
`spatialite` are installed and set `GDAL_LIBRARY_PATH` if needed.

To run the backend tests:

```bash
DJANGO_SETTINGS_MODULE=PlayNexus.settings pytest backend -q
```
If testing on the Android emulator, ensure `ALLOWED_HOSTS` in `.env` includes
`10.0.2.2` so Django accepts requests from the emulator.
The backend exposes a simple auth API supporting email/password and Google login.
After signing up or using Google the app stores JWT tokens securely and the
profile page shows your account email. Use the **Logout** button on that page to
clear the stored token and log in with a different account.

## Geo setup

PostGIS is required for the new facility search API. Docker uses
`postgis/postgis:15-3.4` for the database so no extra setup is needed.
If running locally install PostGIS and set `ENGINE=django.contrib.gis.db.backends.postgis`
in `PlayNexus/settings.py`.

GeoDjango also needs the GDAL and SpatiaLite libraries installed. The
exact package names depend on your platform but the following commands work
on most systems:

```bash
# Debian/Ubuntu
sudo apt-get install gdal-bin libgdal-dev libspatialite7 libspatialite-dev

# macOS (Homebrew)
brew install gdal libspatialite

# Fedora
sudo dnf install gdal gdal-devel libspatialite
```

If these libraries are missing Django will fail at runtime with errors about
missing GDAL or SpatiaLite.

Seed demo data with:

```bash
docker compose exec web python backend/manage.py seed_taxonomy
docker compose exec web python backend/manage.py seed_sports
```
Creates demo sports plus category and variant data so **Add Activity** dropdowns work.

```bash
docker compose exec web python backend/manage.py seed_facilities
```

The seed command creates 30 facilities around the origin (0°, 0°). If your
device's location is far away, no nearby results will appear. Either adjust your
emulator's location to 0,0 or modify the seeder to use coordinates near you.

## Location permissions

The client uses the device's location to show nearby activities. Android
requires `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` to be declared in
`AndroidManifest.xml`. iOS must include `NSLocationWhenInUseUsageDescription` in
`Info.plist`.

## Merchant interface

Logged-in providers can publish new facilities via the **Add** button on the
dashboard. Simply choose a name and categories; the app will use the device's
current location as the facility position. Once created the facility appears in
the *Nearby Activities* list for customers near you.

### Provider sign-up

Use `/api/provider/register/` to create a provider account. The request body
should include `email`, `password1`, `password2`, `company_name`, `phone` and
`address`. On success the server returns access and refresh tokens and a blank
provider profile which can be updated via `/api/provider/profile/`.

## Features

- Provider portal for creating facilities, categories and activities
- Image uploads for category and activity banners
- PostGIS search API to discover nearby facilities
- JWT authentication with email or Google
- Flutter client using Riverpod state management

## Payments and Stripe

The backend uses Stripe for processing payments. Set your Stripe keys in `.env`:

```
STRIPE_API_KEY=sk_test_xxx   # secret key for the Django backend
STRIPE_PUBLIC_KEY=pk_test_xxx # publishable key for the Flutter app
```

After updating the environment file run `flutter pub get` to install the
`flutter_stripe` dependency and rebuild the app.

## Image Upload Setup

Install Pillow and mount the `media/` directory when running the app:

```bash
pip install Pillow
docker compose up -d
```
Uploaded files will appear under `media/` and are served at `/media/` in development.

## Running tests

To run the backend tests locally install a few system packages first (package
names may vary by distribution):

- `gdal` / `libgdal-dev`
- `spatialite` / `libspatialite-dev`

After installing the system dependencies, create a Python virtual environment
and install the project requirements:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
DJANGO_SETTINGS_MODULE=PlayNexus.settings pytest backend -q
```

A helper script `scripts/run_backend_tests.sh` automates the above commands.
Some tests require SpatiaLite which may not work on every platform. Docker is
the recommended environment for running the full test suite.

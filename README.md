# Sports Booking App

This project contains a Flutter client and a Django backend.
The quickest way to try it is with Docker and Flutter:

```bash
# 1. copy environment files and start services
cp .env.example .env
cp backend/.env.example backend/.env
cp mobile/.env.example mobile/.env
# add your Stripe keys in these files
docker compose up -d --build

# 2. apply migrations (first run only)
# note manage.py lives in the backend folder inside the container
docker compose exec web python backend/manage.py migrate --noinput

# 3. optional: load demo sports and facilities
#docker compose exec web python backend/manage.py seed_taxonomy
#docker compose exec web python backend/manage.py seed_sports
#docker compose exec web python backend/manage.py seed_facilities

# 4. collect static files
docker compose exec web python backend/manage.py collectstatic --noinput

# 5. verify the backend is running
curl http://localhost:8000/healthz

# 6. prepare Flutter project
flutter clean
flutter pub get

# 7. run the app on an emulator/device
flutter run

The Android project uses `FlutterFragmentActivity` to support the Stripe
PaymentSheet. If running on a physical device over HTTP you may need to enable
cleartext traffic in `android/app/src/main/AndroidManifest.xml`.
The minimum SDK version is set to 23 in `android/app/build.gradle.kts`.

```

The Docker image runs `collectstatic` during build and serves the compiled
assets with [WhiteNoise](https://whitenoise.evans.io/) so the Django admin loads
its CSS correctly when deployed.

`mobile/.env` must define `API_BASE_URL` so the Flutter app knows where the
backend is. It should also include the publishable Stripe key used by the payment flow.
When testing on the Android emulator the correct value for `API_BASE_URL` is
`http://10.0.2.2:8000/api`.
`initApiClient` automatically appends a trailing slash so either form
(`http://10.0.2.2:8000/api` or `http://10.0.2.2:8000/api/`) works.
For Web or desktop builds the Android emulator host `10.0.2.2` is not reachable;
the client automatically swaps it to `127.0.0.1` so the backend running on the
same machine can be accessed without editing `.env`.

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

## 本次变更与回归步骤

### 启动

后端:

```bash
cd backend
python manage.py runserver
```

前端:

```bash
# 确保 .env 中配置 API_BASE_URL (Android 模拟器使用 http://10.0.2.2:8000/api)
flutter run
```

### 手工回归用例

1. **创建后立即可见**
   - Given 已登录商家, 在商家端创建 Slot
   - When 创建成功返回
   - Then “My Slots” 页刷新后能立即看到该 Slot
2. **普通用户支付预订**
   - Given 普通用户打开活动详情并选择商家 Slot
   - When 点击支付并完成流程
   - Then 订单创建且状态为 confirmed
3. **商家自订拦截**
   - Given 商家尝试预订自己创建的 Slot
   - When 进入支付页或直接调用接口
   - Then 前端按钮禁用且提示，API 返回 403 `cannot_book_own_slot`

## Geo setup

PostGIS is required for the new facility search API. Docker uses
`postgis/postgis:15-3.4` for the database so no extra setup is needed.
If running locally install PostGIS and set `ENGINE=django.contrib.gis.db.backends.postgis`
in `PlayNexus/settings.py`.
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
The `geocoding` package is used to translate typed addresses into coordinates;
no additional setup is required beyond network access.

## Merchant interface

Logged-in providers can publish new facilities via the **Add** button on the
dashboard. Simply choose a name and categories; the app will use the device's
current location as the facility position. Once created the facility appears in
the *Nearby Activities* list for customers near you.
All create forms return to the previous screen with
`Navigator.pop(context, true)` so the caller can `await` the result and refresh
its data when a new item is added.

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

## Activities by Category API

`GET /api/activities/?category=<id>&page=<n>&page_size=<m>` returns activities
filtered by the given category. All activity list endpoints now return a
paginated JSON object with `count`, `next`, `previous` and `results` fields.
Use the items under `results` on the client.

## Search API

`GET /api/activities/?q=<query>&page=<n>` performs a text search across
activity titles, descriptions and sport names. Optional `category` narrows the
results. Facilities support the same `q` parameter. Enable trigram indexes for
Postgres by setting `USE_TRIGRAM=True` in `backend/.env` and applying migrations.

Disable pagination temporarily by passing `?no_page=1`.

```bash
curl -s "http://127.0.0.1:8000/api/activities/?category=1&page=1&page_size=20"
curl -s "http://127.0.0.1:8000/api/activities/?no_page=1"
```

Ensure the backend is running (`python backend/manage.py runserver`) before
issuing the request.

On the client you can tap any category card to view its activities, pull down to
refresh and load more when reaching the end of the list.

## Payments and Stripe

The backend uses Stripe for processing payments. Obtain test keys from your
Stripe dashboard (**Developers → API keys** in test mode) and set them in the
respective environment files:

```
backend/.env:
STRIPE_API_KEY=sk_test_xxx   # secret key for the Django backend
STRIPE_WEBHOOK_SECRET=whsec_xxx

mobile/.env:
STRIPE_PUBLIC_KEY=pk_test_xxx
API_BASE_URL=http://10.0.2.2:8000/api
```

`manage.py` and the Django settings automatically load variables from
`backend/.env` when running locally.

After updating the environment file run `flutter pub get` to install the
`flutter_stripe` dependency and rebuild the app.

To run the backend locally without Docker:

```bash
pip install -r requirements.txt
python backend/manage.py migrate
python backend/manage.py runserver 0.0.0.0:8000
```

For webhook handling during development you can use the Stripe CLI:

```bash
stripe login
stripe listen --forward-to http://127.0.0.1:8000/api/payments/webhook/
# copy the displayed whsec_* value into `.env` as STRIPE_WEBHOOK_SECRET
```

Use the test card **4242 4242 4242 4242** with any future expiry and CVC.

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

## Booking timeout cleanup

Pending bookings older than 30 minutes can be cleaned up with:

```
python backend/manage.py bookings_cancel_timeouts
```

To run it periodically add a cron job such as:

```
*/10 * * * * python /path/to/backend/manage.py bookings_cancel_timeouts
```

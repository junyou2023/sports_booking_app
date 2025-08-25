# Testing Guide

All commands assume you are at the project root using **Command Prompt (cmd.exe)**:

```
C:\Users\23293\Desktop\sports_booking_app2>
```

## Install Development Dependencies

```cmd
python -m pip install -r requirements-dev.txt
```

## Backend Tests & Coverage

```cmd
python manage.py test
pytest --maxfail=1
coverage run --source="." manage.py test
coverage report -m
coverage html -d reports\coverage_html
```

## Performance & Webhook Utilities

```cmd
python manage.py perf_nearby --lat <LAT> --lng <LON> --radius 10000 --runs 10
stripe listen --forward-to localhost:8000/<payments_webhook_path>
bash scripts\timings.sh <BASE_URL>
```

## Flutter Frontend Tests

```cmd
flutter test --coverage
```

## Notes
- Replace `<LAT>`, `<LON>`, `<BASE_URL>` with actual values before running.
- No external network calls are made during tests; Stripe and geospatial features are mocked or skipped if unsupported.
- Some advanced behaviours are currently marked `xfail`/`skip`.

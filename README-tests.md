# Testing Guide

All commands assume you are at the project root:
```
(.venv) PS C:\Users\23293\Desktop\sports_booking_app2>
```

## Install Development Dependencies
```bash
python -m pip install -r requirements-dev.txt
```

## Backend Tests & Coverage
```bash
make test-backend          # run Django tests with coverage
make test-backend-pytest   # run pytest directly
make cov                   # generate coverage HTML report
```

## Performance & Webhook Utilities
```bash
make perf-nearby --lat <LAT> --lng <LON> --radius 10000 --runs 10  # PostGIS performance
make stripe-listen                                            # forward Stripe webhooks locally
bash scripts/timings.sh <BASE_URL>                            # simple endpoint timings
```

## Flutter Frontend Tests
```bash
flutter test --coverage
```

## Optional Legacy Commands
```bash
cd backend
coverage run -m pytest -q --disable-warnings || true
coverage json -o ../results/coverage-summary.json
coverage report -m | tee ../results/coverage-report.txt
python manage.py bench_endpoints --out ../results/perf.csv
```

## Notes
- Replace `<LAT>`, `<LON>`, `<BASE_URL>` with actual values before running.
- No external network calls are made during tests; Stripe and geospatial features are mocked or skipped if unsupported.
- Some advanced behaviours are currently marked `xfail`/`skip`.

# Test & Evidence Runner

## Quick Start
```bash
cd backend
coverage run -m pytest -q --disable-warnings || true
coverage json -o ../results/coverage-summary.json
coverage report -m | tee ../results/coverage-report.txt
```

## Performance Benchmarks
```bash
cd backend
python manage.py bench_endpoints --out ../results/perf.csv
```

## Notes
- Stripe and external services are stubbed via fixtures; no network calls are made.
- Geospatial tests skip automatically if GDAL/PostGIS is unavailable.
- Some advanced behaviors (failed payment seat release, JWT refresh) are marked `xfail`/`skip` pending implementation.

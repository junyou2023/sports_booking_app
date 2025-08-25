test-backend: ## Run Django tests with coverage
coverage run --source='.' manage.py test && coverage report -m && coverage html -d reports/coverage_html

test-backend-pytest: ## Run pytest
pytest --maxfail=1

cov: ## Generate coverage HTML only
coverage html -d reports/coverage_html

perf-nearby: ## Run nearby performance command
python manage.py perf_nearby --lat $LAT --lng $LON --radius 10000 --runs 10

stripe-listen: ## Forward stripe webhook locally
stripe listen --forward-to localhost:8000/api/payments/webhook/

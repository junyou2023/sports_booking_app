#!/usr/bin/env bash
set -euo pipefail

# Create and activate Python virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
python -m pip install -r requirements.txt

# Run the Django test suite
DJANGO_SETTINGS_MODULE=PlayNexus.settings pytest backend "$@"

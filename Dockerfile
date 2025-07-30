# ── Dockerfile ──
# ---------------------------------------
# 1) Base image and dependencies remain unchanged
FROM python:3.11-slim
RUN apt-get update \
    && apt-get install -y gdal-bin libgdal-dev \
    && apt-get clean
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# collect static assets at build time
ENV DJANGO_SETTINGS_MODULE=PlayNexus.settings

# ---------------------------------------
# 2) Copy backend code
COPY backend ./backend

RUN python backend/manage.py collectstatic --noinput

# ---------------------------------------
# 3) Important tweak: make /app part of Python search path
ENV PYTHONPATH="/app/backend:/app:${PYTHONPATH}"

# ---------------------------------------
# 4) Start using the prefixed wsgi module
CMD ["gunicorn", "backend.PlayNexus.wsgi:application", "--bind", "0.0.0.0:8000"]
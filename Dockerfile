# ── Dockerfile ──
# ---------------------------------------
# 1) 基础镜像和依赖保持原样
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
# 2) 把后端代码拷进去
COPY backend ./backend

RUN python backend/manage.py collectstatic --noinput

# ---------------------------------------
# 3) 关键补丁：让 /app 成为 Python 顶层包搜索路径
ENV PYTHONPATH="/app/backend:/app:${PYTHONPATH}"

# ---------------------------------------
# 4) 用带前缀的 wsgi 启动
CMD ["gunicorn", "backend.PlayNexus.wsgi:application", "--bind", "0.0.0.0:8000"]
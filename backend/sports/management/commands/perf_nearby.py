import os
import csv
import time
import statistics
from django.core.management.base import BaseCommand
from django.db import connection
from django.apps import apps

class Command(BaseCommand):
    help = "Run EXPLAIN ANALYZE on nearby query multiple times and report P50/P95"

    def add_arguments(self, parser):
        parser.add_argument('--lat', type=float, required=True)
        parser.add_argument('--lng', type=float, required=True)
        parser.add_argument('--radius', type=int, default=10000)
        parser.add_argument('--runs', type=int, default=10)

    def handle(self, *args, **opts):
        Facility = apps.get_model('sports', 'Facility')
        table = Facility._meta.db_table
        lat = opts['lat']
        lng = opts['lng']
        radius = opts['radius']
        runs = opts['runs']
        times = []
        with connection.cursor() as cur:
            for _ in range(runs):
                start = time.time()
                cur.execute(
                    f"""
                    EXPLAIN ANALYZE
                    SELECT id FROM {table}
                    WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(%s,%s),4326), %s);
                    """,
                    [lng, lat, radius],
                )
                cur.fetchall()
                times.append((time.time() - start) * 1000.0)
        p50 = statistics.median(times)
        p95 = sorted(times)[max(0, int(0.95 * len(times)) - 1)]
        self.stdout.write(f"P50={p50:.1f}ms, P95={p95:.1f}ms")
        os.makedirs('reports', exist_ok=True)
        with open('reports/nearby_perf.csv', 'w', newline='') as f:
            w = csv.writer(f)
            w.writerow(['run', 'ms'])
            for i, t in enumerate(times):
                w.writerow([i + 1, t])

import os
import time
import csv
import statistics
from django.core.management.base import BaseCommand
from rest_framework.test import APIClient

class Command(BaseCommand):
    help = "Bench simple endpoints and write CSV with avg and p95 latency."

    def add_arguments(self, parser):
        parser.add_argument("--out", default="results/perf.csv")
        parser.add_argument("--iterations", type=int, default=5)

    def handle(self, *args, **opts):
        client = APIClient()
        endpoints = [
            ("/api/activities/", {}),
            ("/api/slots/", {}),
            ("/api/bookings/", {}),
        ]
        rows = [("endpoint", "avg_ms", "p95_ms")]
        for url, params in endpoints:
            times = []
            for _ in range(opts["iterations"]):
                start = time.perf_counter()
                client.get(url, params)
                times.append((time.perf_counter() - start) * 1000)
            avg = sum(times) / len(times)
            p95 = statistics.quantiles(times, n=100)[94] if len(times) > 1 else times[0]
            rows.append((url, round(avg, 2), round(p95, 2)))
        out = opts["out"]
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", newline="") as f:
            csv.writer(f).writerows(rows)
        self.stdout.write(self.style.SUCCESS(f"saved to {out}"))

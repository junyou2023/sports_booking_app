"""Locust load testing script for booking API."""
from locust import HttpUser, task, between


class BookingUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def search_activities(self):
        self.client.get("/api/activities/", params={"q": "run"})

    @task(1)
    def create_booking(self):
        # This assumes a slot with ID 1 exists; adjust as necessary
        self.client.post("/api/payments/checkout/", json={"slot": 1})


# To execute: run `locust -f scripts/load_test.py --users 50 --spawn-rate 10`
# Then open http://localhost:8089 to start the test and monitor response times.

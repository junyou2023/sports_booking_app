#!/usr/bin/env bash
set -e
AUTH="Authorization: Bearer ${PN_ACCESS:-REPLACE_TOKEN}"
BASE=${1:-http://localhost:8000}
mkdir -p reports
echo "# endpoint timings" > reports/timings.txt
curl -s -o /dev/null -w "nearby_total_ms:%{time_total}\n" \
  -H "$AUTH" "$BASE/api/facilities?near=55.8721,-4.2890&radius=10000" | tee -a reports/timings.txt
curl -s -o /dev/null -w "booking_post_ms:%{time_total}\n" \
  -H "$AUTH" -H "Content-Type: application/json" -d '{"slot": [[TO_FILL_SLOT_ID]]}' \
  -X POST "$BASE/api/bookings/" | tee -a reports/timings.txt

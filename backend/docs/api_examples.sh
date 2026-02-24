#!/bin/bash
BASE_URL="http://localhost:8000/api/v1"

echo "=== 1. Register ==="
curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@zense.kz","password":"test1234","display_name":"Test User"}' | python3 -m json.tool

echo -e "\n=== 2. Login ==="
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@zense.kz","password":"demo1234"}')
echo $TOKEN_RESPONSE | python3 -m json.tool
TOKEN=$(echo $TOKEN_RESPONSE | python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")
AUTH="Authorization: Bearer $TOKEN"

echo -e "\n=== 3. Get Profile ==="
curl -s "$BASE_URL/profile" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 4. Create Income ==="
curl -s -X POST "$BASE_URL/incomes/" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"amount":"45000","source_type":"freelance","received_at":"2026-02-24T10:00:00Z","note":"Design project"}' | python3 -m json.tool

echo -e "\n=== 5. Create Expense ==="
curl -s -X POST "$BASE_URL/expenses/" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"amount":"5500","category":"food","spent_at":"2026-02-24T13:00:00Z","merchant_name":"Wolt"}' | python3 -m json.tool

echo -e "\n=== 6. List Expenses ==="
curl -s "$BASE_URL/expenses/?limit=5" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 7. Create Goal ==="
curl -s -X POST "$BASE_URL/goals/" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"title":"MacBook Air","target_amount":"750000","priority":1,"category":"gadget"}' | python3 -m json.tool

echo -e "\n=== 8. Generate Budget Plan ==="
curl -s -X POST "$BASE_URL/budgets/plan/generate" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"period_type":"weekly"}' | python3 -m json.tool

echo -e "\n=== 9. Safe to Spend Today ==="
curl -s "$BASE_URL/budgets/safe-to-spend/today" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 10. Budget Health Check ==="
curl -s "$BASE_URL/budgets/health-check" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 11. Purchase Impact Simulator ==="
curl -s -X POST "$BASE_URL/simulator/purchase-impact" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"purchase_amount":"25000","category":"shopping"}' | python3 -m json.tool

echo -e "\n=== 12. Anti-Impulse Start ==="
IMPULSE_RESPONSE=$(curl -s -X POST "$BASE_URL/anti-impulse/start" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"planned_purchase_amount":"15000","category":"entertainment"}')
echo $IMPULSE_RESPONSE | python3 -m json.tool
SESSION_ID=$(echo $IMPULSE_RESPONSE | python3 -c "import sys,json;print(json.load(sys.stdin)['session_id'])")

echo -e "\n=== 13. Anti-Impulse Resolve ==="
curl -s -X POST "$BASE_URL/anti-impulse/$SESSION_ID/resolve" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"outcome":"postponed"}' | python3 -m json.tool

echo -e "\n=== 14. Generate Weekly Report ==="
curl -s -X POST "$BASE_URL/reports/weekly/generate" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 15. AI Coach Ask ==="
curl -s -X POST "$BASE_URL/ai/coach/ask" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"user_message":"I want to buy new shoes but I am saving for a phone"}' | python3 -m json.tool

echo -e "\n=== 16. AI Coach Insights ==="
curl -s "$BASE_URL/ai/coach/insights/latest" -H "$AUTH" | python3 -m json.tool

echo -e "\n=== 17. Goal Contribute ==="
GOALS=$(curl -s "$BASE_URL/goals/" -H "$AUTH")
GOAL_ID=$(echo $GOALS | python3 -c "import sys,json;data=json.load(sys.stdin);print(data[0]['id'] if data else '')")
if [ -n "$GOAL_ID" ]; then
  curl -s -X POST "$BASE_URL/goals/$GOAL_ID/contribute" \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d '{"amount":"5000","source":"manual","note":"Weekly contribution"}' | python3 -m json.tool
fi

echo -e "\n=== 18. Dashboard Summary ==="
curl -s "$BASE_URL/analytics/dashboard/summary" -H "$AUTH" | python3 -m json.tool

echo -e "\nDone! All endpoints tested."

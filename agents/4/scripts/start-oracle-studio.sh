#!/usr/bin/env bash
# Oracle Studio — oracle-v2 มี UI built-in ที่ /swagger
# bunx oracle-studio ไม่มีบน npm (404) — script นี้ probe + แสดง URL

API_URL="${ORACLE_API_URL:-http://localhost:47778}"

echo "=== Oracle Studio ==="

if curl -sf "${API_URL}/" > /dev/null 2>&1; then
  VERSION=$(curl -s "${API_URL}/" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  echo "  ✓ oracle-v2 running — version: ${VERSION}"
  echo ""
  echo "  Studio (Swagger UI) → ${API_URL}/swagger"
  echo "  REST API            → ${API_URL}/api"
  echo "  Health              → ${API_URL}/"
  echo ""
  echo "  เปิดใน browser:"
  echo "    WSL2:    explorer.exe \"${API_URL}/swagger\""
  echo "    Linux:   xdg-open \"${API_URL}/swagger\" 2>/dev/null || echo \"open ${API_URL}/swagger\""
else
  echo "  ✗ oracle-v2 ไม่ได้รัน — start ก่อน:"
  echo "    bash scripts/start-oracle-v2-http.sh"
  exit 1
fi

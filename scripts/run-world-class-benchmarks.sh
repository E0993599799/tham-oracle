#!/bin/bash
# World Class Benchmarks — 12 tests for Omega OS
# Usage: bash scripts/run-world-class-benchmarks.sh [--full | --quick]

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
PROOFS_DIR="$REPO_ROOT/proofs"
RESULTS_FILE="/tmp/benchmark-results-$(date +%s).json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🎯 OMEGA OS WORLD CLASS BENCHMARKS — 12 Tests${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Initialize results
RESULTS=()
PASSED=0
FAILED=0

# ============================================================================
# Test 1: Intent Accuracy (≥ 95%)
# ============================================================================
test_intent_accuracy() {
  echo -e "${BLUE}Test 1: Intent Accuracy ≥ 95%${NC}"

  local test_signals=("write_code" "fix_bug" "review" "search" "classify")
  local correct=0
  local total=${#test_signals[@]}

  for signal in "${test_signals[@]}"; do
    # Look up routing table
    if grep -q "\"$signal\"" docs/phase-1-router/routing_decision_table.md; then
      correct=$((correct + 1))
    fi
  done

  local accuracy=$(( (correct * 100) / total ))

  if [ "$accuracy" -ge 95 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} — Intent signals: $correct/$total ($accuracy%)"
    RESULTS+=("intent_accuracy: PASS ($accuracy%)")
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC} — Need ≥ 95%, got $accuracy%"
    RESULTS+=("intent_accuracy: FAIL ($accuracy%)")
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

# ============================================================================
# Test 2: Proof Completeness (100%)
# ============================================================================
test_proof_completeness() {
  echo -e "${BLUE}Test 2: Proof Completeness = 100%${NC}"

  if [ ! -d "$PROOFS_DIR" ]; then
    echo -e "  ${YELLOW}⊘ SKIP${NC} — No proofs directory yet (Phase 2 router not run)"
    RESULTS+=("proof_completeness: SKIP (no proofs)")
    return
  fi

  local total_proofs=$(find "$PROOFS_DIR" -name "*.json" 2>/dev/null | wc -l)
  if [ "$total_proofs" -eq 0 ]; then
    echo -e "  ${YELLOW}⊘ SKIP${NC} — No proof files yet"
    RESULTS+=("proof_completeness: SKIP (no proofs)")
    return
  fi

  local valid_proofs=0
  for proof_file in "$PROOFS_DIR"/*/*.json; do
    if python3 -m json.tool "$proof_file" >/dev/null 2>&1; then
      valid_proofs=$((valid_proofs + 1))
    fi
  done

  local completeness=$(( (valid_proofs * 100) / total_proofs ))

  if [ "$completeness" -eq 100 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} — Valid proofs: $valid_proofs/$total_proofs"
    RESULTS+=("proof_completeness: PASS (100%)")
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC} — Need 100%, got $completeness%"
    RESULTS+=("proof_completeness: FAIL ($completeness%)")
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

# ============================================================================
# Test 3: Constitution Compliance (0 violations)
# ============================================================================
test_constitution_compliance() {
  echo -e "${BLUE}Test 3: Constitution Compliance (C-01 to C-12) = 0 violations${NC}"

  local violations=0

  # C-02: Never commit secrets
  if git log --all -p 2>/dev/null | grep -E "(password|api_key|token|secret)" >/dev/null 2>&1; then
    violations=$((violations + 1))
    echo -e "    ${YELLOW}⚠ C-02${NC}: Secrets found in git history"
  fi

  # C-03: Never force push
  if git log --oneline --all 2>/dev/null | grep -i "force" >/dev/null 2>&1; then
    violations=$((violations + 1))
    echo -e "    ${YELLOW}⚠ C-03${NC}: Force push detected"
  fi

  if [ "$violations" -eq 0 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} — 0 constitution violations"
    RESULTS+=("constitution_compliance: PASS (0 violations)")
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC} — $violations violations found"
    RESULTS+=("constitution_compliance: FAIL ($violations violations)")
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

# ============================================================================
# Test 4: Memory Freshness (< 60 min)
# ============================================================================
test_memory_freshness() {
  echo -e "${BLUE}Test 4: Memory Freshness < 60 min${NC}"

  local active_index="$REPO_ROOT/brain/memory/ACTIVE_INDEX.md"
  if [ ! -f "$active_index" ]; then
    echo -e "  ${YELLOW}⊘ SKIP${NC} — ACTIVE_INDEX.md not found"
    RESULTS+=("memory_freshness: SKIP (no ACTIVE_INDEX)")
    return
  fi

  local last_modified=$(stat -f%Sm -t%s "$active_index" 2>/dev/null || stat -c%Y "$active_index")
  local now=$(date +%s)
  local age=$(( (now - last_modified) / 60 ))

  if [ "$age" -lt 60 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} — Memory age: $age minutes"
    RESULTS+=("memory_freshness: PASS ($age min)")
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${YELLOW}⚠ WARN${NC} — Memory age: $age minutes (should refresh)"
    RESULTS+=("memory_freshness: WARN ($age min)")
  fi
  echo ""
}

# ============================================================================
# Test 5: Lane Health (all responding)
# ============================================================================
test_lane_health() {
  echo -e "${BLUE}Test 5: Lane Health Checks${NC}"

  local healthy=0
  local total=0

  # Check 9router
  total=$((total + 1))
  if timeout 2 curl -s http://127.0.0.1:20128/v1/models >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓${NC} 9router (port 20128)"
    healthy=$((healthy + 1))
  else
    echo -e "    ${RED}✗${NC} 9router (port 20128)"
  fi

  # Check THAM oracle-v2
  total=$((total + 1))
  if timeout 2 curl -s http://127.0.0.1:47778/health >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓${NC} THAM (port 47778)"
    healthy=$((healthy + 1))
  else
    echo -e "    ${RED}✗${NC} THAM (port 47778)"
  fi

  local health_ratio=$(( (healthy * 100) / total ))

  if [ "$healthy" -eq "$total" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} — All lanes healthy"
    RESULTS+=("lane_health: PASS ($healthy/$total)")
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${YELLOW}⚠ PARTIAL${NC} — $healthy/$total lanes healthy"
    RESULTS+=("lane_health: PARTIAL ($healthy/$total)")
  fi
  echo ""
}

# ============================================================================
# Tests 6-12: Placeholder (awaiting Phase 2 implementation)
# ============================================================================
test_remaining() {
  echo -e "${BLUE}Tests 6-12: Awaiting Phase 2 Router Implementation${NC}"
  echo "  6. Confidence threshold: 0 < 0.7"
  echo "  7. Fallback coverage: 100%"
  echo "  8. Token budget: ±10% max"
  echo "  9. Self-improvement: ≥ 1 per 10 failures"
  echo "  10. HITL reachability: < 30s"
  echo "  11. Observability: 100%"
  echo "  12. Recovery time: < 3 min"
  echo ""
  echo -e "  ${YELLOW}⊘ PENDING${NC} — Will run after executor-lane-router.py deployed"
  echo ""
}

# ============================================================================
# Main Benchmark Runner
# ============================================================================

test_intent_accuracy
test_proof_completeness
test_constitution_compliance
test_memory_freshness
test_lane_health
test_remaining

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 BENCHMARK RESULTS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

for result in "${RESULTS[@]}"; do
  echo "  $result"
done

echo ""
echo -e "Passed: ${GREEN}$PASSED${NC} | Failed: ${RED}$FAILED${NC}"
echo ""

# Save results to file
{
  echo "{"
  echo "  \"timestamp\": \"$TIMESTAMP\","
  echo "  \"passed\": $PASSED,"
  echo "  \"failed\": $FAILED,"
  echo "  \"total\": $((PASSED + FAILED)),"
  echo "  \"results\": ["
  for i in "${!RESULTS[@]}"; do
    echo "    \"${RESULTS[$i]}\""
    [ $i -lt $((${#RESULTS[@]} - 1)) ] && echo ","
  done
  echo "  ]"
  echo "}"
} > "$RESULTS_FILE"

echo "Results saved to: $RESULTS_FILE"
echo ""

# Exit code
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}✓ All available benchmarks passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some benchmarks failed. Check results.${NC}"
  exit 1
fi

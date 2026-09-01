#!/bin/bash
# Script to run all tests with coverage

set -e

echo "═══════════════════════════════════════════════════════"
echo "  小学コレ！道徳 - Test Suite Runner"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and report results
run_test() {
    local test_name=$1
    local test_command=$2

    echo -e "${YELLOW}Running: ${test_name}${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}: ${test_name}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ FAILED${NC}: ${test_name}"
        ((FAILED_TESTS++))
    fi

    ((TOTAL_TESTS++))
    echo ""
}

# Step 1: Setup
echo -e "${YELLOW}Step 1: Setup${NC}"
echo "├─ Checking Flutter..."
flutter --version
echo "├─ Checking Dart..."
dart --version
echo "├─ Getting dependencies..."
flutter pub get
echo "├─ Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs
echo -e "${GREEN}✓ Setup complete${NC}\n"

# Step 2: Code Analysis
echo -e "${YELLOW}Step 2: Code Analysis${NC}"
run_test "Flutter Analyze" "flutter analyze"

# Step 3: Unit Tests
echo -e "${YELLOW}Step 3: Unit Tests${NC}"
run_test "Unit Tests" "flutter test --exclude-tags='integration' --coverage"

# Step 4: Integration Tests
echo -e "${YELLOW}Step 4: Integration Tests${NC}"
run_test "App Flow Tests" "flutter test test/integration_tests/app_flow_test.dart -v"
run_test "Firebase Integration Tests" "flutter test test/integration_tests/firebase_integration_test.dart -v"

# Step 5: Performance Tests
echo -e "${YELLOW}Step 5: Performance Tests${NC}"
run_test "Performance Tests" "flutter test test/performance_test.dart"

# Step 6: Coverage Report
echo -e "${YELLOW}Step 6: Coverage Report${NC}"
if [ -f "coverage/lcov.info" ]; then
    echo "├─ Coverage file found"

    if command -v lcov &> /dev/null; then
        echo "├─ Generating HTML report..."
        lcov --list coverage/lcov.info
    fi

    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}✓ HTML report generated${NC} in coverage/html/index.html"
    fi
else
    echo -e "${YELLOW}⚠ Coverage file not found${NC}"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Test Summary"
echo "═══════════════════════════════════════════════════════"
echo "Total Tests Run:  ${TOTAL_TESTS}"
echo -e "Passed:           ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed:           ${RED}${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

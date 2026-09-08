#!/bin/bash

###############################################################################
# QA Test Runner Script
# Purpose: Automate QA test execution tracking and result documentation
# Usage: ./scripts/qa_test_runner.sh [test_type] [device] [os_version]
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$PROJECT_ROOT/test_results"
QA_LOG_FILE="$TEST_RESULTS_DIR/qa_test_log_$(date +%Y%m%d_%H%M%S).md"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

###############################################################################
# Helper Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

log_to_file() {
    echo "$1" >> "$QA_LOG_FILE"
}

###############################################################################
# Test Categories
###############################################################################

test_basic_functionality() {
    local device=$1
    local os=$2

    print_header "Basic Functionality Tests - $device ($os)"

    log_to_file "## Basic Functionality Tests"
    log_to_file "- Device: $device"
    log_to_file "- OS: $os"
    log_to_file "- Test Date: $(date)"
    log_to_file ""

    tests=(
        "Authentication Flow|Login/Register/Password Reset"
        "Child Profile|Create/Edit/Delete/Multiple Children"
        "Story Learning|Load/Select/Branch/Results"
        "Badge System|Earning/Display/Progress"
        "Monthly Report|Display/Trends/AI Comments"
        "Settings|Language/Volume/Notifications/Cache"
    )

    log_to_file "### Test Results"
    log_to_file ""

    for test in "${tests[@]}"; do
        name="${test%%|*}"
        details="${test##*|}"
        echo -n "Testing $name ... "
        read -p "Result (PASS/FAIL): " result

        if [ "$result" = "PASS" ]; then
            log_success "$name"
            log_to_file "- [✓] $name: $details"
        else
            log_error "$name"
            log_to_file "- [✗] $name: $details"
            read -p "Issue description: " issue_desc
            log_to_file "  - Issue: $issue_desc"
        fi
    done
}

test_network_conditions() {
    local device=$1
    local os=$2

    print_header "Network Condition Tests - $device ($os)"

    log_to_file "## Network Condition Tests"
    log_to_file "- Device: $device"
    log_to_file "- OS: $os"
    log_to_file ""
    log_to_file "### Test Results"
    log_to_file ""

    tests=(
        "WiFi Connection|Normal speed connectivity"
        "Mobile Data|LTE/5G speed test"
        "Network Disconnect|Offline mode operation"
        "Low Speed Network|2G simulation"
        "Packet Loss|5-10% packet loss handling"
        "Network Switch|WiFi to Mobile transition"
    )

    for test in "${tests[@]}"; do
        name="${test%%|*}"
        details="${test##*|}"
        echo -n "Testing $name ... "
        read -p "Result (PASS/FAIL): " result

        if [ "$result" = "PASS" ]; then
            log_success "$name"
            log_to_file "- [✓] $name: $details"
        else
            log_error "$name"
            log_to_file "- [✗] $name: $details"
            read -p "Issue description: " issue_desc
            log_to_file "  - Issue: $issue_desc"
        fi
    done
}

test_performance() {
    local device=$1
    local os=$2

    print_header "Performance Tests - $device ($os)"

    log_to_file "## Performance Tests"
    log_to_file "- Device: $device"
    log_to_file "- OS: $os"
    log_to_file ""
    log_to_file "### Test Results"
    log_to_file ""

    echo "Memory Usage (check in developer settings or Xcode/Android Studio)"
    read -p "Home Screen Memory (MB): " home_mem
    read -p "Story Loading Memory (MB): " story_mem
    read -p "Report Display Memory (MB): " report_mem

    log_to_file "- Home Screen Memory: ${home_mem}MB"
    log_to_file "- Story Loading Memory: ${story_mem}MB"
    log_to_file "- Report Display Memory: ${report_mem}MB"

    echo ""
    read -p "App Cold Start Time (seconds): " cold_start
    read -p "App Hot Start Time (seconds): " hot_start
    read -p "Story Load Time (seconds): " story_load

    log_to_file "- Cold Start: ${cold_start}s"
    log_to_file "- Hot Start: ${hot_start}s"
    log_to_file "- Story Load: ${story_load}s"

    echo ""
    tests=(
        "Memory < 250MB|Peak memory usage acceptable"
        "CPU < 80%|CPU usage within limits"
        "Battery|Battery consumption reasonable"
        "FPS 60|60 FPS maintained"
    )

    log_to_file ""
    for test in "${tests[@]}"; do
        name="${test%%|*}"
        read -p "$name (PASS/FAIL): " result

        if [ "$result" = "PASS" ]; then
            log_to_file "- [✓] $name"
        else
            log_to_file "- [✗] $name"
        fi
    done
}

test_accessibility() {
    local device=$1
    local os=$2

    print_header "Accessibility Tests - $device ($os)"

    log_to_file "## Accessibility Tests"
    log_to_file "- Device: $device"
    log_to_file "- OS: $os"
    log_to_file ""
    log_to_file "### Test Results"
    log_to_file ""

    tests=(
        "Screen Reader|Text read aloud correctly"
        "Text Zoom 200%|Layout maintains at max zoom"
        "Color Contrast|WCAG AA standard met"
        "Dark Mode|Proper colors in dark mode"
    )

    for test in "${tests[@]}"; do
        name="${test%%|*}"
        details="${test##*|}"
        echo -n "Testing $name ... "
        read -p "Result (PASS/FAIL): " result

        if [ "$result" = "PASS" ]; then
            log_success "$name"
            log_to_file "- [✓] $name: $details"
        else
            log_error "$name"
            log_to_file "- [✗] $name: $details"
            read -p "Issue description: " issue_desc
            log_to_file "  - Issue: $issue_desc"
        fi
    done
}

test_ui_ux() {
    local device=$1
    local os=$2

    print_header "UI/UX Tests - $device ($os)"

    log_to_file "## UI/UX Tests"
    log_to_file "- Device: $device"
    log_to_file "- OS: $os"
    log_to_file ""
    log_to_file "### Test Results"
    log_to_file ""

    tests=(
        "Layout|Proper layout for device size"
        "Japanese Text|Correct display of Japanese"
        "Illustrations|Images display properly"
        "Gestures|Tap/Swipe/Scroll work correctly"
    )

    for test in "${tests[@]}"; do
        name="${test%%|*}"
        details="${test##*|}"
        echo -n "Testing $name ... "
        read -p "Result (PASS/FAIL): " result

        if [ "$result" = "PASS" ]; then
            log_success "$name"
            log_to_file "- [✓] $name: $details"
        else
            log_error "$name"
            log_to_file "- [✗] $name: $details"
            read -p "Issue description: " issue_desc
            log_to_file "  - Issue: $issue_desc"
        fi
    done
}

###############################################################################
# Main Menu
###############################################################################

show_menu() {
    echo ""
    echo "QA Test Runner - Select Test Category"
    echo "======================================"
    echo "1) Basic Functionality"
    echo "2) Network Conditions"
    echo "3) Performance"
    echo "4) Accessibility"
    echo "5) UI/UX"
    echo "6) Full Test Suite"
    echo "7) View Test Results"
    echo "8) Exit"
    echo ""
    read -p "Select option (1-8): " option
}

main() {
    print_header "小学コレ！心身 QA Test Runner"

    log_info "Test Results Directory: $TEST_RESULTS_DIR"
    log_info "QA Log File: $QA_LOG_FILE"

    # Initialize log file
    echo "# QA Test Results" > "$QA_LOG_FILE"
    echo "Generated: $(date)" >> "$QA_LOG_FILE"
    echo "" >> "$QA_LOG_FILE"

    read -p "Device Name (e.g., iPhone 15, Pixel 8): " device
    read -p "OS Version (e.g., iOS 17, Android 14): " os_version

    while true; do
        show_menu

        case $option in
            1) test_basic_functionality "$device" "$os_version" ;;
            2) test_network_conditions "$device" "$os_version" ;;
            3) test_performance "$device" "$os_version" ;;
            4) test_accessibility "$device" "$os_version" ;;
            5) test_ui_ux "$device" "$os_version" ;;
            6)
                test_basic_functionality "$device" "$os_version"
                test_network_conditions "$device" "$os_version"
                test_performance "$device" "$os_version"
                test_accessibility "$device" "$os_version"
                test_ui_ux "$device" "$os_version"
                ;;
            7) cat "$QA_LOG_FILE" ;;
            8)
                log_info "Test session completed. Results saved to: $QA_LOG_FILE"
                exit 0
                ;;
            *) log_error "Invalid option. Please select 1-8." ;;
        esac
    done
}

###############################################################################
# Entry Point
###############################################################################

main "$@"

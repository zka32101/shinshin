#!/usr/bin/env python3
"""
Test Suite Runner for 小学コレ！道徳

This script runs all tests with coverage reporting and detailed output.
"""

import subprocess
import sys
import os
from pathlib import Path
from datetime import datetime

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def print_header(text):
    """Print a formatted header"""
    print(f"\n{Colors.BLUE}{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}{Colors.NC}\n")

def print_step(step_num, text):
    """Print a step"""
    print(f"{Colors.YELLOW}Step {step_num}: {text}{Colors.NC}")

def print_success(text):
    """Print a success message"""
    print(f"{Colors.GREEN}✓ {text}{Colors.NC}")

def print_error(text):
    """Print an error message"""
    print(f"{Colors.RED}✗ {text}{Colors.NC}")

def print_warning(text):
    """Print a warning message"""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.NC}")

def run_command(command, description=""):
    """Run a command and return success status"""
    try:
        if description:
            print(f"  ├─ {description}...", end=" ", flush=True)

        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            cwd=str(Path(__file__).parent.parent)
        )

        if result.returncode == 0:
            if description:
                print_success("")
            return True
        else:
            if description:
                print_error("")
            else:
                print(result.stderr)
            return False

    except Exception as e:
        print_error(f"Error: {e}")
        return False

def main():
    """Main test runner function"""
    print_header("小学コレ！道徳 - Test Suite Runner")

    # Project root
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)

    # Test results
    test_results = {}
    total_tests = 0
    passed_tests = 0

    # Step 1: Setup
    print_step(1, "Setup")
    setup_success = True

    setup_success &= run_command("flutter --version", "Checking Flutter")
    setup_success &= run_command("dart --version", "Checking Dart")
    setup_success &= run_command("flutter pub get", "Getting dependencies")
    setup_success &= run_command(
        "flutter pub run build_runner build --delete-conflicting-outputs",
        "Running build_runner"
    )

    if setup_success:
        print_success("Setup complete")
    else:
        print_error("Setup failed")
        return 1

    # Step 2: Code Analysis
    print_step(2, "Code Analysis")
    total_tests += 1
    if run_command("flutter analyze", "Flutter Analyze"):
        test_results["Flutter Analyze"] = "PASSED"
        passed_tests += 1
    else:
        test_results["Flutter Analyze"] = "FAILED"

    # Step 3: Unit Tests
    print_step(3, "Unit Tests")
    total_tests += 1
    if run_command(
        "flutter test --exclude-tags='integration' --coverage",
        "Unit Tests"
    ):
        test_results["Unit Tests"] = "PASSED"
        passed_tests += 1
    else:
        test_results["Unit Tests"] = "FAILED"

    # Step 4: Integration Tests
    print_step(4, "Integration Tests")

    # App Flow Tests
    total_tests += 1
    if run_command(
        "flutter test test/integration_tests/app_flow_test.dart -v",
        "App Flow Tests"
    ):
        test_results["App Flow Tests"] = "PASSED"
        passed_tests += 1
    else:
        test_results["App Flow Tests"] = "FAILED"

    # Firebase Integration Tests
    total_tests += 1
    if run_command(
        "flutter test test/integration_tests/firebase_integration_test.dart -v",
        "Firebase Integration Tests"
    ):
        test_results["Firebase Integration Tests"] = "PASSED"
        passed_tests += 1
    else:
        test_results["Firebase Integration Tests"] = "FAILED"

    # Step 5: Performance Tests
    print_step(5, "Performance Tests")
    total_tests += 1
    perf_output = "perf_results.txt"
    if run_command(
        f"flutter test test/performance_test.dart --verbose 2>&1 | tee {perf_output}",
        "Performance Tests"
    ):
        test_results["Performance Tests"] = "PASSED"
        passed_tests += 1
    else:
        test_results["Performance Tests"] = "FAILED"

    # Step 6: Coverage Report
    print_step(6, "Coverage Report")

    coverage_file = project_root / "coverage" / "lcov.info"
    if coverage_file.exists():
        print(f"  ├─ Coverage file found")

        # Try to generate HTML report
        html_result = subprocess.run(
            "genhtml coverage/lcov.info -o coverage/html",
            shell=True,
            capture_output=True,
            cwd=str(project_root)
        )

        if html_result.returncode == 0:
            print_success("HTML report generated in coverage/html/index.html")
        else:
            print_warning("Could not generate HTML report (genhtml not installed)")

        # Try to display coverage
        lcov_result = subprocess.run(
            "lcov --list coverage/lcov.info",
            shell=True,
            capture_output=True,
            text=True,
            cwd=str(project_root)
        )

        if lcov_result.returncode == 0:
            print(lcov_result.stdout)
    else:
        print_warning("Coverage file not found")

    # Summary
    print_header("Test Summary")
    print(f"Test Run Date:    {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total Tests:      {total_tests}")
    print(f"Passed:           {Colors.GREEN}{passed_tests}{Colors.NC}")
    print(f"Failed:           {Colors.RED}{total_tests - passed_tests}{Colors.NC}")
    print()

    # Detailed results
    print("Detailed Results:")
    print("-" * 60)
    for test_name, result in test_results.items():
        if result == "PASSED":
            print(f"  {Colors.GREEN}✓{Colors.NC} {test_name}: {result}")
        else:
            print(f"  {Colors.RED}✗{Colors.NC} {test_name}: {result}")

    # Final status
    print()
    if total_tests - passed_tests == 0:
        print_success("All tests passed!")
        return 0
    else:
        print_error(f"{total_tests - passed_tests} test(s) failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())

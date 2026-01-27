#!/bin/bash

# Load Testing Runner Script
# Runs all tests against both Bun and Elixir implementations

set -e

BUN_URL="http://localhost:3000"
ELIXIR_URL="http://localhost:4000"

echo "🧪 Load Testing Comparison: Bun vs Elixir"
echo "=========================================="
echo ""

# Function to run a test
run_test() {
    local test_name=$1
    local test_file=$2
    local base_url=$3
    local impl_name=$4
    
    echo "📊 Running $test_name on $impl_name..."
    echo "URL: $base_url"
    echo ""
    
    k6 run --env BASE_URL=$base_url $test_file
    
    echo ""
    echo "✅ $test_name completed for $impl_name"
    echo "=========================================="
    echo ""
}

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "❌ k6 is not installed. Please install it first:"
    echo "   https://k6.io/docs/getting-started/installation/"
    exit 1
fi

# Test selection
TEST_TYPE=${1:-"all"}

case $TEST_TYPE in
    "baseline")
        echo "Running baseline load tests..."
        run_test "Baseline Load Test" "baseline-load.js" $BUN_URL "Bun"
        run_test "Baseline Load Test" "baseline-load.js" $ELIXIR_URL "Elixir"
        ;;
    
    "stress")
        echo "Running stress tests..."
        run_test "Stress Test" "stress-load.js" $BUN_URL "Bun"
        run_test "Stress Test" "stress-load.js" $ELIXIR_URL "Elixir"
        ;;
    
    "chaos")
        echo "Running chaos + load tests..."
        run_test "Chaos + Load Test" "chaos-load.js" $BUN_URL "Bun"
        run_test "Chaos + Load Test" "chaos-load.js" $ELIXIR_URL "Elixir"
        ;;
    
    "all")
        echo "Running all tests..."
        echo ""
        
        echo "1️⃣  BASELINE LOAD TESTS"
        echo "======================="
        run_test "Baseline Load Test" "baseline-load.js" $BUN_URL "Bun"
        run_test "Baseline Load Test" "baseline-load.js" $ELIXIR_URL "Elixir"
        
        echo "2️⃣  STRESS TESTS"
        echo "================"
        run_test "Stress Test" "stress-load.js" $BUN_URL "Bun"
        run_test "Stress Test" "stress-load.js" $ELIXIR_URL "Elixir"
        
        echo "3️⃣  CHAOS + LOAD TESTS"
        echo "======================"
        run_test "Chaos + Load Test" "chaos-load.js" $BUN_URL "Bun"
        run_test "Chaos + Load Test" "chaos-load.js" $ELIXIR_URL "Elixir"
        ;;
    
    *)
        echo "Usage: $0 [baseline|stress|chaos|all]"
        echo ""
        echo "  baseline - Run baseline load tests (100 users)"
        echo "  stress   - Run stress tests (1000-5000 users)"
        echo "  chaos    - Run chaos + load tests (500 users with failures)"
        echo "  all      - Run all tests (default)"
        exit 1
        ;;
esac

echo ""
echo "🎉 All tests completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Compare the results from both implementations"
echo "   2. Look for differences in:"
echo "      - Response time percentiles (p95, p99)"
echo "      - Error rates"
echo "      - Throughput"
echo "      - System stability under chaos"

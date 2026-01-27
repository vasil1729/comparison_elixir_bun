#!/bin/bash

# Automated Benchmark Runner
# Runs complete benchmark suite with resource monitoring and report generation

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$RESULTS_DIR/run_$TIMESTAMP"

echo "🚀 Elixir vs Bun - Automated Benchmark Suite"
echo "=============================================="
echo ""

# Create results directory
mkdir -p "$RUN_DIR"

# Check if servers are running
check_server() {
    local url=$1
    local name=$2
    
    if curl -s "$url/health" > /dev/null 2>&1; then
        echo "✅ $name server is running"
        return 0
    else
        echo "❌ $name server is NOT running at $url"
        return 1
    fi
}

echo "📡 Checking servers..."
check_server "http://localhost:3000" "Bun" || {
    echo ""
    echo "Please start the Bun server first:"
    echo "  cd bun-baseline && bun run start"
    exit 1
}

check_server "http://localhost:4000" "Elixir" || {
    echo ""
    echo "Please start the Elixir server first:"
    echo "  cd elixir-candidate && mix run --no-halt"
    exit 1
}

echo ""
echo "📊 Results will be saved to: $RUN_DIR"
echo ""

# Function to run a test with monitoring
run_test() {
    local test_name=$1
    local test_file=$2
    local duration=$3
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Running: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Start resource monitoring in background
    echo "📊 Starting resource monitoring..."
    cd "$PROJECT_ROOT/scripts"
    ./monitor-resources.sh start $duration "${test_name}" &
    MONITOR_PID=$!
    
    sleep 2
    
    # Run k6 tests for both implementations
    cd "$PROJECT_ROOT/load-tests"
    
    echo ""
    echo "🔵 Testing Bun implementation..."
    k6 run --env BASE_URL=http://localhost:3000 \
        --out json="$RUN_DIR/${test_name}_bun_k6.json" \
        "$test_file" || echo "⚠️  Bun test completed with errors"
    
    echo ""
    echo "🟣 Testing Elixir implementation..."
    k6 run --env BASE_URL=http://localhost:4000 \
        --out json="$RUN_DIR/${test_name}_elixir_k6.json" \
        "$test_file" || echo "⚠️  Elixir test completed with errors"
    
    # Wait for monitoring to complete
    wait $MONITOR_PID 2>/dev/null || true
    
    # Move resource monitoring results
    mv "$PROJECT_ROOT/scripts/results/${test_name}_"*.csv "$RUN_DIR/" 2>/dev/null || true
    
    echo ""
    echo "✅ $test_name completed"
}

# Run all tests
echo "Starting benchmark suite..."
echo ""

# Test 1: Baseline Load
run_test "baseline_load" "baseline-load.js" 120

# Small pause between tests
echo ""
echo "⏸️  Pausing 10 seconds before next test..."
sleep 10

# Test 2: Stress Load
run_test "stress_load" "stress-load.js" 480

# Small pause between tests
echo ""
echo "⏸️  Pausing 10 seconds before next test..."
sleep 10

# Test 3: Chaos Load
run_test "chaos_load" "chaos-load.js" 180

# Generate comparison report
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Generating comparison report..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_ROOT/scripts"
if [ -f "generate-report.js" ]; then
    node generate-report.js "$RUN_DIR"
    echo "✅ Report generated: $RUN_DIR/comparison_report.html"
else
    echo "⚠️  Report generator not found, skipping..."
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Benchmark Suite Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Results saved to: $RUN_DIR"
echo ""
echo "Files generated:"
ls -lh "$RUN_DIR" | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
echo ""
echo "Next steps:"
echo "  1. Open comparison_report.html in your browser"
echo "  2. Review the metrics and charts"
echo "  3. Share results with stakeholders"
echo ""

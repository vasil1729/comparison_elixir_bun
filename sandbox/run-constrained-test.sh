#!/bin/bash

# Constrained sandbox testing with extrapolation
# Usage: ./run-constrained-test.sh [bun|elixir|both]

set -e

TARGET="${1:-both}"
RESULTS_DIR="./results/constrained_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔬 Constrained Sandbox Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Constraints:${NC}"
echo "  CPU: 1 core"
echo "  Memory: 512MB"
echo "  Duration: 30 seconds"
echo "  Load: 50 concurrent users"
echo ""

# Function to monitor resources in real-time
monitor_resources() {
    local container_name=$1
    local output_file=$2
    local duration=$3
    
    echo "timestamp,cpu_percent,mem_mb,mem_percent" > "$output_file"
    
    local end_time=$((SECONDS + duration))
    while [ $SECONDS -lt $end_time ]; do
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            local stats=$(docker stats "$container_name" --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" 2>/dev/null || echo "0%,0MiB / 0MiB")
            local cpu=$(echo "$stats" | cut -d',' -f1 | tr -d '%')
            local mem_usage=$(echo "$stats" | cut -d',' -f2 | cut -d'/' -f1 | tr -d 'MiB' | xargs)
            local mem_limit=$(echo "$stats" | cut -d',' -f2 | cut -d'/' -f2 | tr -d 'MiB' | xargs)
            local mem_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_usage / $mem_limit) * 100}")
            
            echo "$(date +%s),$cpu,$mem_usage,$mem_percent" >> "$output_file"
        fi
        sleep 1
    done
}

# Function to run test for a service
run_test() {
    local service=$1
    local port=$2
    local name=$3
    
    echo -e "${GREEN}Testing: $name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Wait for service to be ready
    echo "Waiting for service to be ready..."
    for i in {1..30}; do
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo "✓ Service ready"
            break
        fi
        sleep 1
    done
    
    # Start resource monitoring in background
    local monitor_file="$RESULTS_DIR/${service}_resources.csv"
    monitor_resources "sandbox-${service}-1" "$monitor_file" 35 &
    local monitor_pid=$!
    
    # Run k6 test
    echo "Running load test..."
    TARGET_URL="http://localhost:$port" k6 run \
        --quiet \
        --no-color \
        quick-test.js > "$RESULTS_DIR/${service}_summary.json" 2>&1
    
    # Wait for monitoring to finish
    wait $monitor_pid
    
    # Parse results
    local summary=$(cat "$RESULTS_DIR/${service}_summary.json")
    local throughput=$(echo "$summary" | jq -r '.iterations_per_second // 0')
    local p95_latency=$(echo "$summary" | jq -r '.http_req_duration_p95 // 0')
    local error_rate=$(echo "$summary" | jq -r '.http_req_failed_rate // 0')
    
    # Calculate average CPU and memory from monitoring
    local avg_cpu=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}' "$monitor_file")
    local avg_mem=$(awk -F',' 'NR>1 {sum+=$3; count++} END {if(count>0) printf "%.0f", sum/count; else print "0"}' "$monitor_file")
    local max_cpu=$(awk -F',' 'NR>1 {if($2>max) max=$2} END {printf "%.1f", max}' "$monitor_file")
    
    echo ""
    echo -e "${BLUE}Results:${NC}"
    echo "  Throughput: $(printf "%.1f" $throughput) req/s"
    echo "  P95 Latency: $(printf "%.0f" $p95_latency) ms"
    echo "  Error Rate: $(printf "%.2f" $(echo "$error_rate * 100" | bc))%"
    echo "  Avg CPU: ${avg_cpu}%"
    echo "  Max CPU: ${max_cpu}%"
    echo "  Avg Memory: ${avg_mem} MB"
    echo ""
    
    # Store for extrapolation
    echo "$service,$throughput,$p95_latency,$error_rate,$avg_cpu,$max_cpu,$avg_mem" >> "$RESULTS_DIR/results.csv"
}

# Initialize results file
echo "service,throughput_rps,p95_latency_ms,error_rate,avg_cpu,max_cpu,avg_mem_mb" > "$RESULTS_DIR/results.csv"

# Run tests
if [ "$TARGET" = "bun" ] || [ "$TARGET" = "both" ]; then
    run_test "bun-baseline" "3000" "Bun Baseline"
fi

if [ "$TARGET" = "elixir" ] || [ "$TARGET" = "both" ]; then
    run_test "elixir-candidate" "4000" "Elixir Candidate"
fi

# Generate extrapolation report
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Extrapolation to Production${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Read results and extrapolate
while IFS=',' read -r service throughput p95 error_rate avg_cpu max_cpu avg_mem; do
    if [ "$service" = "service" ]; then continue; fi
    
    echo -e "${GREEN}$service:${NC}"
    echo "  Constrained (1 CPU core, 512MB):"
    echo "    - Throughput: $(printf "%.1f" $throughput) req/s"
    echo "    - CPU Usage: ${avg_cpu}% avg, ${max_cpu}% max"
    echo ""
    
    # Extrapolate to 8-core server
    local throughput_8core=$(echo "$throughput * 7" | bc) # 7x for ~87% efficiency
    local servers_for_1000rps=$(echo "1000 / $throughput_8core" | bc)
    local servers_for_10000rps=$(echo "10000 / $throughput_8core" | bc)
    
    echo "  Extrapolated (8 CPU cores, 4GB RAM):"
    echo "    - Expected throughput: $(printf "%.0f" $throughput_8core) req/s"
    echo "    - Servers needed for 1,000 req/s: $(printf "%.1f" $servers_for_1000rps)"
    echo "    - Servers needed for 10,000 req/s: $(printf "%.1f" $servers_for_10000rps)"
    echo ""
    
    # Cost estimation
    local cost_per_server=200
    local monthly_cost_1k=$(echo "$servers_for_1000rps * $cost_per_server" | bc)
    local monthly_cost_10k=$(echo "$servers_for_10000rps * $cost_per_server" | bc)
    
    echo "  Estimated Infrastructure Cost:"
    echo "    - For 1,000 req/s: \$$(printf "%.0f" $monthly_cost_1k)/month"
    echo "    - For 10,000 req/s: \$$(printf "%.0f" $monthly_cost_10k)/month"
    echo ""
    
done < "$RESULTS_DIR/results.csv"

echo -e "${YELLOW}Results saved to: $RESULTS_DIR${NC}"
echo ""

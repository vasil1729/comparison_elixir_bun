#!/bin/bash

# Resource Monitor Script
# Monitors CPU, memory, and process count for both servers during load tests

set -e

BUN_PORT=3000
ELIXIR_PORT=4000
OUTPUT_DIR="./results"
INTERVAL=2  # seconds between measurements

# Create output directory
mkdir -p $OUTPUT_DIR

# Function to get process stats
get_stats() {
    local port=$1
    local name=$2
    local output_file=$3
    
    # Find PID by port
    local pid=$(lsof -ti:$port 2>/dev/null || echo "")
    
    if [ -z "$pid" ]; then
        echo "$(date +%s),,,,not_running" >> $output_file
        return
    fi
    
    # Get CPU and memory usage
    local stats=$(ps -p $pid -o %cpu,%mem,rss,vsz 2>/dev/null | tail -n 1)
    local cpu=$(echo $stats | awk '{print $1}')
    local mem=$(echo $stats | awk '{print $2}')
    local rss=$(echo $stats | awk '{print $3}')
    local vsz=$(echo $stats | awk '{print $4}')
    
    # Count child processes (for Elixir, this shows BEAM processes)
    local children=$(pgrep -P $pid 2>/dev/null | wc -l)
    
    echo "$(date +%s),$cpu,$mem,$rss,$vsz,$children" >> $output_file
}

# Function to monitor both servers
monitor() {
    local duration=$1
    local test_name=$2
    
    local bun_file="$OUTPUT_DIR/${test_name}_bun.csv"
    local elixir_file="$OUTPUT_DIR/${test_name}_elixir.csv"
    
    # Write headers
    echo "timestamp,cpu_percent,mem_percent,rss_kb,vsz_kb,child_processes" > $bun_file
    echo "timestamp,cpu_percent,mem_percent,rss_kb,vsz_kb,child_processes" > $elixir_file
    
    echo "📊 Monitoring servers for ${duration}s..."
    echo "   Bun (port $BUN_PORT) -> $bun_file"
    echo "   Elixir (port $ELIXIR_PORT) -> $elixir_file"
    
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        get_stats $BUN_PORT "Bun" $bun_file
        get_stats $ELIXIR_PORT "Elixir" $elixir_file
        
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        
        # Progress indicator
        echo -ne "\rProgress: ${elapsed}s / ${duration}s"
    done
    
    echo -e "\n✅ Monitoring complete!"
}

# Main script
case "${1:-help}" in
    start)
        DURATION=${2:-60}
        TEST_NAME=${3:-"manual_test"}
        monitor $DURATION $TEST_NAME
        ;;
    
    baseline)
        echo "🧪 Starting baseline load test monitoring..."
        monitor 120 "baseline_load"
        ;;
    
    stress)
        echo "🧪 Starting stress test monitoring..."
        monitor 480 "stress_load"
        ;;
    
    chaos)
        echo "🧪 Starting chaos test monitoring..."
        monitor 180 "chaos_load"
        ;;
    
    *)
        echo "Resource Monitor for Elixir vs Bun Comparison"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  start <duration> <name>  - Monitor for specified duration (seconds)"
        echo "  baseline                 - Monitor during baseline test (120s)"
        echo "  stress                   - Monitor during stress test (480s)"
        echo "  chaos                    - Monitor during chaos test (180s)"
        echo ""
        echo "Output: CSV files in ./results/ directory"
        echo ""
        echo "Example:"
        echo "  $0 start 60 my_test"
        echo "  $0 chaos"
        ;;
esac

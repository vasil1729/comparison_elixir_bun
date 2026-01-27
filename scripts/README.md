# Scripts Directory

Automation and analysis scripts for the Elixir vs Bun comparison demo.

## Available Scripts

### 1. Resource Monitor (`monitor-resources.sh`)

Monitors CPU, memory, and process count for both servers during tests.

**Usage:**

```bash
# Monitor for 60 seconds
./monitor-resources.sh start 60 my_test

# Monitor during specific test
./monitor-resources.sh baseline  # 120s
./monitor-resources.sh stress    # 480s
./monitor-resources.sh chaos     # 180s
```

**Output:** CSV files in `./results/` directory with columns:

- `timestamp` - Unix timestamp
- `cpu_percent` - CPU usage percentage
- `mem_percent` - Memory usage percentage
- `rss_kb` - Resident set size in KB
- `vsz_kb` - Virtual memory size in KB
- `child_processes` - Number of child processes

---

### 2. Automated Benchmark Runner (`run-full-benchmark.sh`)

Runs complete benchmark suite with monitoring and report generation.

**Usage:**

```bash
# Make sure both servers are running first!
# Terminal 1: cd bun-baseline && bun run start
# Terminal 2: cd elixir-candidate && mix run --no-halt

# Then run the benchmark
./run-full-benchmark.sh
```

**What it does:**

1. Checks if both servers are running
2. Runs all three load tests (baseline, stress, chaos)
3. Monitors resource usage during tests
4. Generates comparison report
5. Saves everything to timestamped directory

**Duration:** ~15 minutes total

---

### 3. Comparison Report Generator (`generate-report.js`)

Parses k6 JSON output and resource CSVs to create HTML comparison report.

**Usage:**

```bash
node generate-report.js <results_directory>

# Example
node generate-report.js ../results/run_20260127_193000
```

**Output:** `comparison_report.html` with:

- Side-by-side metrics comparison
- Latency percentiles (p50, p95, p99)
- Error rates
- Resource usage (CPU, memory)
- Visual charts and graphs

---

## Workflow

### Quick Test

```bash
# Start monitoring
./monitor-resources.sh chaos &

# Run chaos test
cd ../load-tests
./run-tests.sh chaos

# Generate report
cd ../scripts
node generate-report.js ./results
```

### Full Benchmark Suite

```bash
# One command does everything!
./run-full-benchmark.sh

# Results saved to: ./results/run_<timestamp>/
# Open: ./results/run_<timestamp>/comparison_report.html
```

---

## Requirements

- **lsof** - For finding process by port
- **ps** - For process statistics
- **Node.js** - For report generation
- **k6** - For load testing
- Both servers must be running

---

## Output Structure

```
results/
└── run_20260127_193000/
    ├── baseline_load_bun_k6.json
    ├── baseline_load_elixir_k6.json
    ├── baseline_load_bun.csv
    ├── baseline_load_elixir.csv
    ├── stress_load_bun_k6.json
    ├── stress_load_elixir_k6.json
    ├── stress_load_bun.csv
    ├── stress_load_elixir.csv
    ├── chaos_load_bun_k6.json
    ├── chaos_load_elixir_k6.json
    ├── chaos_load_bun.csv
    ├── chaos_load_elixir.csv
    └── comparison_report.html  ⭐
```

---

## Tips

- Run tests during off-peak hours for consistent results
- Close other applications to minimize interference
- Run multiple times and average results
- Save reports with descriptive names for comparison

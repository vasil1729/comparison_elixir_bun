# Load Testing Scripts

k6 load testing scripts for comparing Bun and Elixir implementations under various conditions.

## Prerequisites

Install k6:

```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows
choco install k6
```

## Test Scenarios

### 1. Baseline Load Test (`baseline-load.js`)

- **Load**: 100 concurrent users
- **Duration**: 2 minutes
- **Purpose**: Establish baseline performance under normal load
- **Thresholds**:
  - p95 < 500ms
  - Error rate < 10%

### 2. Stress Test (`stress-load.js`)

- **Load**: Ramps from 1000 → 5000 users
- **Duration**: 8 minutes
- **Purpose**: Test system behavior under heavy load
- **Thresholds**:
  - p95 < 2000ms
  - Error rate < 20%

### 3. Chaos + Load Test (`chaos-load.js`)

- **Load**: 500 concurrent users
- **Duration**: 3 minutes
- **Chaos**: Enabled (random failures, delays, crashes)
- **Purpose**: Test fault tolerance and recovery
- **Thresholds**:
  - p95 < 3000ms
  - Error rate < 30%

## Running Tests

### Individual Tests

```bash
# Baseline test against Bun
k6 run --env BASE_URL=http://localhost:3000 baseline-load.js

# Baseline test against Elixir
k6 run --env BASE_URL=http://localhost:4000 baseline-load.js

# Stress test against Bun
k6 run --env BASE_URL=http://localhost:3000 stress-load.js

# Chaos test against Elixir
k6 run --env BASE_URL=http://localhost:4000 chaos-load.js
```

### Automated Test Suite

```bash
# Run all tests against both implementations
./run-tests.sh all

# Run only baseline tests
./run-tests.sh baseline

# Run only stress tests
./run-tests.sh stress

# Run only chaos tests
./run-tests.sh chaos
```

## Expected Results

### Bun Baseline

- ✅ Good performance under normal load
- ⚠️ Degradation under stress
- ❌ Cascading failures under chaos
- ❌ Event loop blocking visible

### Elixir Candidate

- ✅ Consistent performance under all loads
- ✅ Graceful degradation under stress
- ✅ Isolated failures under chaos
- ✅ Automatic recovery

## Metrics to Compare

1. **Response Time**
   - p50 (median)
   - p95 (95th percentile)
   - p99 (99th percentile)

2. **Throughput**
   - Requests per second
   - Success rate

3. **Stability**
   - Error rate
   - Recovery time after failures

4. **Resource Usage** (monitor separately)
   - Memory consumption
   - CPU usage

## Interpreting Results

Look for these observable differences:

| Metric           | Bun (Expected) | Elixir (Expected) |
| ---------------- | -------------- | ----------------- |
| Baseline p95     | < 500ms        | < 200ms           |
| Stress p95       | > 2000ms       | < 1000ms          |
| Chaos error rate | > 30%          | < 15%             |
| Recovery         | Manual         | Automatic         |

## Tips

- Run each test multiple times for consistency
- Monitor system resources during tests
- Clear state between test runs
- Ensure both servers are running before testing
- Use `--out json=results.json` to save detailed results

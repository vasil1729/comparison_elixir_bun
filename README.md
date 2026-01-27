# Elixir vs Bun Order Processing Comparison

A demonstrative comparison showing **Elixir's superiority** for high-concurrency, failure-prone backend systems through observable proof, not opinions.

## 🎯 Goal

Build the **same order processing system** in both Bun and Elixir, then stress-test them under chaos to clearly demonstrate:

- ✅ Better stability under load
- ✅ Failure isolation
- ✅ Automatic recovery
- ✅ Lower operational complexity

## 📁 Project Structure

```
comparision_elixir_bun/
├── bun-baseline/          # Traditional event-loop implementation
├── elixir-candidate/      # OTP-based implementation (coming soon)
├── load-tests/            # k6 load testing scripts (coming soon)
└── README.md
```

## 🚀 Quick Start

### Bun Baseline

```bash
cd bun-baseline
bun install
bun run start
```

Server runs on `http://localhost:3000`

### Elixir Candidate

```bash
cd elixir-candidate
mix deps.get
mix phx.server
```

Server runs on `http://localhost:4000`

## 📊 API Endpoints (Identical for Both)

### Create Order

```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"item": "widget", "quantity": 5}'
```

### Get Order Status

```bash
curl http://localhost:3000/orders/{order_id}
```

### Enable Chaos Mode

```bash
curl -X POST http://localhost:3000/chaos
```

### Health Check

```bash
curl http://localhost:3000/health
```

### Statistics

```bash
curl http://localhost:3000/stats
```

## 🔥 Chaos Engineering

Both implementations support chaos injection that randomly triggers:

- **Random Exceptions** (15%) - Unexpected errors
- **Artificial Latency** (10%) - 3-5 second delays
- **CPU-Heavy Tasks** (5%) - Event loop blocking
- **Worker Crashes** (5%) - Process failures

## 🧪 Load Testing

Load tests will demonstrate observable differences:

1. **Baseline Load** - 1,000 concurrent requests
2. **Stress Load** - 10,000-50,000 concurrent requests
3. **Chaos + Load** - Combined stress testing

### Quick Test

```bash
cd load-tests
./run-tests.sh chaos
```

### Full Automated Benchmark

```bash
# Start both servers first, then:
cd scripts
./run-full-benchmark.sh

# Results saved to: ./results/run_<timestamp>/
# Open: ./results/run_<timestamp>/comparison_report.html
```

## 🛠️ Automation Scripts

### Resource Monitoring

```bash
cd scripts
./monitor-resources.sh chaos  # Monitor during chaos test
```

### Comparison Report

```bash
node generate-report.js ../results/run_<timestamp>
```

See [scripts/README.md](./scripts/README.md) for details.

## 📈 Expected Results

| Metric            | Bun Baseline | Elixir Candidate |
| ----------------- | ------------ | ---------------- |
| Failure isolation | ❌           | ✅               |
| Auto recovery     | ❌           | ✅               |
| Stable latency    | ❌           | ✅               |
| Memory behavior   | Grows        | Flat             |
| Ops intervention  | High         | Low              |

## 🎓 Key Takeaway

> **This is not about developer preference.**
> **This is about building systems that stay calm when production is on fire.**

## 📝 Status

- [x] Bun baseline implementation
- [x] Elixir candidate implementation
- [x] Load testing infrastructure
- [x] Resource monitoring & metrics
- [x] Automated benchmark runner
- [x] Comparison report generator
- [x] Unit tests
- [ ] Run actual benchmarks (requires both servers running)

## 🔗 Learn More

- [Planning Document](./PLANNING.md) - Original detailed plan
- [Bun Implementation](./bun-baseline/README.md)
- [Elixir Implementation](./elixir-candidate/README.md) (coming soon)

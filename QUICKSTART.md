# 🚀 Quick Start Guide

## Prerequisites

- ✅ Bun (installed at `~/.bun/bin/bun`)
- ⚠️ Elixir (needs to be in PATH)
- ⚠️ k6 (for load testing)

## 1. Start Bun Server (Port 3000)

```bash
cd bun-baseline
~/.bun/bin/bun install
~/.bun/bin/bun run start
```

## 2. Start Elixir Server (Port 4000)

```bash
cd elixir-candidate
mix deps.get
mix run --no-halt
```

## 3. Quick Test

```bash
# Test Bun
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"item": "test"}'

# Test Elixir
curl -X POST http://localhost:4000/orders \
  -H "Content-Type: application/json" \
  -d '{"item": "test"}'
```

## 4. Enable Chaos

```bash
# Enable chaos on Bun
curl -X POST http://localhost:3000/chaos

# Enable chaos on Elixir
curl -X POST http://localhost:4000/chaos
```

## 5. Run Load Tests

```bash
cd load-tests
./run-tests.sh chaos  # Start with chaos test to see the difference!
```

## Expected Outcome

**Bun**: System becomes unstable, high error rates, cascading failures

**Elixir**: System remains stable, isolated failures, automatic recovery

---

## Next Steps

See [walkthrough.md](file:///C:/Users/vasil/.gemini/antigravity/brain/8422fc1c-2c2a-4f43-be3a-52afcdc1d319/walkthrough.md) for detailed explanation and results interpretation.

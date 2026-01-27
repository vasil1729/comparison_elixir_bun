# Elixir Candidate Order Processor

This is the **Elixir/OTP implementation** demonstrating fault-tolerant, concurrent order processing using the BEAM VM.

## Architecture

- **HTTP Server**: Plug + Cowboy
- **Concurrency Model**: Lightweight processes (one per order)
- **State Management**: ETS (Erlang Term Storage)
- **Supervision**: DynamicSupervisor with automatic restart
- **Fault Tolerance**: Process isolation + automatic recovery

## Key Characteristics

### Strengths

- **Process Isolation**: Each order runs in its own process
- **Automatic Recovery**: Supervisor restarts failed processes
- **True Concurrency**: Millions of lightweight processes
- **Fault Tolerance**: Failures don't cascade
- **Stable Performance**: Predictable under load

### Expected Behavior Under Stress

- ✅ Stable response times
- ✅ Isolated failures (one order crash doesn't affect others)
- ✅ Automatic retry and recovery
- ✅ Flat memory usage
- ✅ No manual intervention needed

## Installation

```bash
mix deps.get
```

## Running

```bash
# Development mode
mix run --no-halt

# Or with interactive shell
iex -S mix
```

Server runs on `http://localhost:4000` by default.

## API Endpoints

### Create Order

```bash
curl -X POST http://localhost:4000/orders \
  -H "Content-Type: application/json" \
  -d '{"item": "widget", "quantity": 5}'
```

### Get Order Status

```bash
curl http://localhost:4000/orders/{order_id}
```

### Enable Chaos Mode

```bash
curl -X POST http://localhost:4000/chaos
```

### Health Check

```bash
curl http://localhost:4000/health
```

### Statistics

```bash
curl http://localhost:4000/stats
```

## Chaos Injection

When chaos mode is enabled via `POST /chaos`, the system will randomly inject:

- **Random Exceptions** (15% chance) - Simulates unexpected errors
- **Artificial Latency** (10% chance) - 3-5 second delays
- **CPU-Heavy Tasks** (5% chance) - Does NOT block other processes!
- **Process Crashes** (5% chance) - Automatically restarted by supervisor

## Expected Behavior Under Load

1. **Normal Load**: Fast, consistent response times
2. **High Load**: Scales linearly, maintains performance
3. **Chaos + Load**:
   - Failed orders isolated to their own process
   - Automatic retry with exponential backoff
   - Other orders continue unaffected
   - System remains responsive
   - **No manual intervention required**

## OTP Supervision Tree

```
ElixirCandidate.Supervisor
├── ElixirCandidate.OrderStore (ETS)
├── ElixirCandidate.OrderSupervisor (DynamicSupervisor)
│   ├── OrderProcessor (order 1)
│   ├── OrderProcessor (order 2)
│   └── OrderProcessor (order N)
├── ElixirCandidate.Chaos
└── Plug.Cowboy (HTTP Server)
```

## Why This Works

- **Process Isolation**: Each order is a separate OS-level process
- **Preemptive Scheduling**: BEAM scheduler prevents starvation
- **Automatic Recovery**: Supervisors restart crashed processes
- **No Shared State**: Failures can't cascade
- **Built for Concurrency**: Not bolted on, but fundamental to the platform

## Testing

```bash
# Simple load test
for i in {1..100}; do
  curl -X POST http://localhost:4000/orders \
    -H "Content-Type: application/json" \
    -d '{"test": true}' &
done
```

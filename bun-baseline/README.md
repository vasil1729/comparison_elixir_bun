# Bun Baseline Order Processor

This is the **baseline implementation** using Bun runtime to demonstrate traditional event-loop based concurrency patterns.

## Architecture

- **HTTP Server**: Fastify
- **Concurrency Model**: Event loop with worker pool
- **State Management**: In-memory Map
- **Job Queue**: In-memory array
- **Retry Logic**: Manual implementation

## Key Characteristics

### Strengths

- Fast startup time
- Low memory footprint (initially)
- Simple architecture

### Expected Weaknesses Under Stress

- Event loop blocking during CPU-intensive tasks
- Cascading failures when workers are overwhelmed
- Queue backpressure issues
- Memory growth under sustained load
- No automatic recovery from failures

## Installation

```bash
bun install
```

## Running

```bash
# Development mode with auto-reload
bun run dev

# Production mode
bun run start
```

Server runs on `http://localhost:3000` by default.

## API Endpoints

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

## Chaos Injection

When chaos mode is enabled via `POST /chaos`, the system will randomly inject:

- **Random Exceptions** (15% chance) - Simulates unexpected errors
- **Artificial Latency** (10% chance) - 3-5 second delays
- **CPU-Heavy Tasks** (5% chance) - Blocks event loop for 500ms
- **Worker Crashes** (5% chance) - Simulates process failures

## Expected Behavior Under Load

1. **Normal Load**: Performs well, fast response times
2. **High Load**: Queue builds up, response times increase
3. **Chaos + Load**:
   - Event loop blocking causes cascading delays
   - Failed orders may not retry properly
   - System becomes unresponsive
   - Manual intervention required

## Testing

```bash
# Simple load test
for i in {1..100}; do
  curl -X POST http://localhost:3000/orders \
    -H "Content-Type: application/json" \
    -d '{"test": true}' &
done
```

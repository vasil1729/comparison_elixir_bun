#!/bin/bash
# Quick test script for Bun baseline server

echo "🧪 Testing Bun Baseline Server..."
echo ""

# Test health endpoint
echo "1. Testing /health endpoint..."
curl -s http://localhost:3000/health | jq .
echo ""

# Create an order
echo "2. Creating an order..."
ORDER_RESPONSE=$(curl -s -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"item": "widget", "quantity": 5}')
echo $ORDER_RESPONSE | jq .
ORDER_ID=$(echo $ORDER_RESPONSE | jq -r .order_id)
echo ""

# Get order status
echo "3. Getting order status..."
sleep 1
curl -s http://localhost:3000/orders/$ORDER_ID | jq .
echo ""

# Check stats
echo "4. Checking stats..."
curl -s http://localhost:3000/stats | jq .
echo ""

# Enable chaos
echo "5. Enabling chaos mode..."
curl -s -X POST http://localhost:3000/chaos | jq .
echo ""

echo "✅ Basic tests completed!"

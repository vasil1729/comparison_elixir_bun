import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 1000 }, // Ramp up to 1000 users
    { duration: "3m", target: 1000 }, // Stay at 1000 users
    { duration: "1m", target: 5000 }, // Spike to 5000 users
    { duration: "2m", target: 5000 }, // Hold at 5000 users
    { duration: "1m", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"], // 95% of requests should be below 2s under stress
    http_req_failed: ["rate<0.2"], // Less than 20% of requests should fail
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Create an order
  const createRes = http.post(
    `${BASE_URL}/orders`,
    JSON.stringify({
      item: `stress-test-${__VU}-${__ITER}`,
      quantity: Math.floor(Math.random() * 10) + 1,
    }),
    {
      headers: { "Content-Type": "application/json" },
      timeout: "10s",
    },
  );

  check(createRes, {
    "order created": (r) => r.status === 200,
  });

  // Randomly check health endpoint
  if (Math.random() < 0.1) {
    const healthRes = http.get(`${BASE_URL}/health`);
    check(healthRes, {
      "health check ok": (r) => r.status === 200,
    });
  }

  // Minimal sleep to maintain pressure
  sleep(0.1);
}

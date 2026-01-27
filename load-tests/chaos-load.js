import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 500 }, // Ramp up to 500 users
    { duration: "2m", target: 500 }, // Stay at 500 users
    { duration: "30s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<3000"], // More lenient threshold with chaos
    http_req_failed: ["rate<0.3"], // Expect more failures with chaos
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export function setup() {
  // Enable chaos mode before the test
  const chaosRes = http.post(`${BASE_URL}/chaos`);
  console.log("🔥 Chaos mode enabled:", chaosRes.status === 200);
  sleep(2);
}

export default function () {
  // Create an order (chaos is already enabled)
  const createRes = http.post(
    `${BASE_URL}/orders`,
    JSON.stringify({
      item: `chaos-test-${__VU}-${__ITER}`,
      quantity: Math.floor(Math.random() * 10) + 1,
      chaos: true,
    }),
    {
      headers: { "Content-Type": "application/json" },
      timeout: "15s", // Longer timeout due to chaos delays
    },
  );

  check(createRes, {
    "order accepted": (r) => r.status === 200,
  });

  if (createRes.status === 200) {
    const orderId = JSON.parse(createRes.body).order_id;

    // Wait for processing (may take longer with chaos)
    sleep(1);

    // Check order status
    const statusRes = http.get(`${BASE_URL}/orders/${orderId}`, {
      timeout: "5s",
    });

    check(statusRes, {
      "status retrieved": (r) => r.status === 200,
    });
  }

  // Check stats periodically
  if (__ITER % 10 === 0) {
    const statsRes = http.get(`${BASE_URL}/stats`);
    if (statsRes.status === 200) {
      const stats = JSON.parse(statsRes.body);
      console.log(
        `Stats - Total: ${stats.total_orders}, Completed: ${stats.completed}, Failed: ${stats.failed}`,
      );
    }
  }

  sleep(0.5);
}

export function teardown(data) {
  // Get final stats
  const statsRes = http.get(`${BASE_URL}/stats`);
  if (statsRes.status === 200) {
    console.log("Final stats:", statsRes.body);
  }
}

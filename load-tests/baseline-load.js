import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 100 }, // Ramp up to 100 users
    { duration: "1m", target: 100 }, // Stay at 100 users
    { duration: "30s", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
    http_req_failed: ["rate<0.1"], // Less than 10% of requests should fail
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Create an order
  const createRes = http.post(
    `${BASE_URL}/orders`,
    JSON.stringify({ item: "test-widget", quantity: 1 }),
    {
      headers: { "Content-Type": "application/json" },
    },
  );

  check(createRes, {
    "order created": (r) => r.status === 200,
    "has order_id": (r) => JSON.parse(r.body).order_id !== undefined,
  });

  if (createRes.status === 200) {
    const orderId = JSON.parse(createRes.body).order_id;

    // Wait a bit for processing
    sleep(0.5);

    // Check order status
    const statusRes = http.get(`${BASE_URL}/orders/${orderId}`);

    check(statusRes, {
      "status retrieved": (r) => r.status === 200,
      "has status field": (r) => JSON.parse(r.body).status !== undefined,
    });
  }

  sleep(1);
}

// Quick k6 test - minimal data, fast results
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// Custom metrics
const errorRate = new Rate("errors");
const orderLatency = new Trend("order_latency");

export const options = {
  stages: [
    { duration: "5s", target: 10 }, // Warm up
    { duration: "20s", target: 50 }, // Test load
    { duration: "5s", target: 0 }, // Cool down
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"], // 95% under 2s
    errors: ["rate<0.1"], // <10% errors
  },
  // Minimal output
  summaryTrendStats: ["avg", "p(95)", "p(99)", "max"],
};

const BASE_URL = __ENV.TARGET_URL || "http://localhost:3000";

export default function () {
  const orderId = `order-${Date.now()}-${Math.random()}`;

  // Create order
  const createRes = http.post(
    `${BASE_URL}/orders`,
    JSON.stringify({
      orderId: orderId,
      items: [
        { id: "item1", quantity: 2, price: 29.99 },
        { id: "item2", quantity: 1, price: 49.99 },
      ],
    }),
    {
      headers: { "Content-Type": "application/json" },
    },
  );

  const success = check(createRes, {
    "status is 200": (r) => r.status === 200,
    "has orderId": (r) => r.json("orderId") !== undefined,
  });

  errorRate.add(!success);
  orderLatency.add(createRes.timings.duration);

  sleep(0.1); // Small delay between requests
}

export function handleSummary(data) {
  // Return minimal summary
  const summary = {
    duration: data.state.testRunDurationMs / 1000,
    iterations: data.metrics.iterations.values.count,
    vus_max: data.metrics.vus_max.values.value,
    http_reqs: data.metrics.http_reqs.values.count,
    http_req_duration_avg: data.metrics.http_req_duration.values.avg,
    http_req_duration_p95: data.metrics.http_req_duration.values["p(95)"],
    http_req_duration_p99: data.metrics.http_req_duration.values["p(99)"],
    http_req_duration_max: data.metrics.http_req_duration.values.max,
    http_req_failed_rate: data.metrics.http_req_failed
      ? data.metrics.http_req_failed.values.rate
      : 0,
    iterations_per_second: data.metrics.iterations.values.rate,
  };

  return {
    stdout: JSON.stringify(summary, null, 2),
    "summary.json": JSON.stringify(summary),
  };
}

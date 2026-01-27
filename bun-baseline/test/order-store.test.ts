import { describe, test, expect } from "bun:test";
import { orderStore } from "../order-store";

describe("OrderStore", () => {
  test("should create an order with received status", () => {
    const orderId = "test-order-1";
    const order = orderStore.create(orderId, { item: "widget" });
    
    expect(order.id).toBe(orderId);
    expect(order.status).toBe("received");
    expect(order.retryCount).toBe(0);
    expect(order.data).toEqual({ item: "widget" });
  });

  test("should get an existing order", () => {
    const orderId = "test-order-2";
    orderStore.create(orderId);
    
    const retrieved = orderStore.get(orderId);
    expect(retrieved).toBeDefined();
    expect(retrieved?.id).toBe(orderId);
  });

  test("should update order status", () => {
    const orderId = "test-order-3";
    orderStore.create(orderId);
    
    orderStore.updateStatus(orderId, "processing");
    const order = orderStore.get(orderId);
    
    expect(order?.status).toBe("processing");
  });

  test("should increment retry count", () => {
    const orderId = "test-order-4";
    orderStore.create(orderId);
    
    orderStore.incrementRetry(orderId);
    orderStore.incrementRetry(orderId);
    
    const order = orderStore.get(orderId);
    expect(order?.retryCount).toBe(2);
  });

  test("should return all orders", () => {
    orderStore.clear();
    
    orderStore.create("order-1");
    orderStore.create("order-2");
    orderStore.create("order-3");
    
    const all = orderStore.getAll();
    expect(all.length).toBe(3);
  });
});

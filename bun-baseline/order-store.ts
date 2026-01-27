/**
 * In-memory order state management
 * Stores order status and provides thread-safe access
 */

export type OrderStatus = "received" | "processing" | "completed" | "failed";

export interface Order {
  id: string;
  status: OrderStatus;
  createdAt: Date;
  updatedAt: Date;
  retryCount: number;
  data?: any;
}

class OrderStore {
  private orders: Map<string, Order> = new Map();

  create(id: string, data?: any): Order {
    const order: Order = {
      id,
      status: "received",
      createdAt: new Date(),
      updatedAt: new Date(),
      retryCount: 0,
      data,
    };
    this.orders.set(id, order);
    return order;
  }

  get(id: string): Order | undefined {
    return this.orders.get(id);
  }

  updateStatus(id: string, status: OrderStatus): void {
    const order = this.orders.get(id);
    if (order) {
      order.status = status;
      order.updatedAt = new Date();
      this.orders.set(id, order);
    }
  }

  incrementRetry(id: string): void {
    const order = this.orders.get(id);
    if (order) {
      order.retryCount++;
      this.orders.set(id, order);
    }
  }

  getAll(): Order[] {
    return Array.from(this.orders.values());
  }

  clear(): void {
    this.orders.clear();
  }
}

export const orderStore = new OrderStore();

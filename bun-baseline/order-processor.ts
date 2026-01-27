/**
 * Background order processor with chaos injection
 * Simulates order processing with intentional failures
 */

import { orderStore } from './order-store';

interface QueuedOrder {
  id: string;
  data?: any;
}

class OrderProcessor {
  private queue: QueuedOrder[] = [];
  private processing = false;
  private chaosEnabled = false;
  private maxRetries = 3;
  private workerCount = 0;
  private maxWorkers = 100; // Simulate limited worker pool

  enqueue(orderId: string, data?: any): void {
    this.queue.push({ id: orderId, data });
    this.processQueue();
  }

  enableChaos(): void {
    this.chaosEnabled = true;
    console.log('🔥 CHAOS MODE ENABLED');
  }

  private async processQueue(): Promise<void> {
    if (this.processing || this.queue.length === 0) {
      return;
    }

    this.processing = true;

    while (this.queue.length > 0 && this.workerCount < this.maxWorkers) {
      const order = this.queue.shift();
      if (order) {
        this.workerCount++;
        this.processOrder(order).finally(() => {
          this.workerCount--;
        });
      }
    }

    this.processing = false;
  }

  private async processOrder(order: QueuedOrder): Promise<void> {
    const { id } = order;
    
    try {
      orderStore.updateStatus(id, 'processing');
      
      // Simulate processing work
      await this.simulateWork(id);
      
      orderStore.updateStatus(id, 'completed');
    } catch (error) {
      console.error(`Order ${id} failed:`, error);
      
      const currentOrder = orderStore.get(id);
      if (currentOrder && currentOrder.retryCount < this.maxRetries) {
        // Retry logic
        orderStore.incrementRetry(id);
        console.log(`Retrying order ${id} (attempt ${currentOrder.retryCount + 1})`);
        
        // Re-queue with delay
        setTimeout(() => {
          this.enqueue(id, order.data);
        }, 1000 * currentOrder.retryCount);
      } else {
        orderStore.updateStatus(id, 'failed');
      }
    }
  }

  private async simulateWork(orderId: string): Promise<void> {
    // Base processing time
    const baseDelay = Math.random() * 100 + 50;
    
    if (this.chaosEnabled) {
      await this.injectChaos(orderId);
    }
    
    await this.sleep(baseDelay);
  }

  private async injectChaos(orderId: string): Promise<void> {
    const chaosType = Math.random();
    
    if (chaosType < 0.15) {
      // 15% chance: Random exception
      throw new Error(`Random failure for order ${orderId}`);
    } else if (chaosType < 0.25) {
      // 10% chance: Artificial latency (3-5 seconds)
      const delay = Math.random() * 2000 + 3000;
      console.log(`⏱️  Order ${orderId}: Injecting ${delay}ms delay`);
      await this.sleep(delay);
    } else if (chaosType < 0.30) {
      // 5% chance: CPU-heavy task (blocks event loop)
      console.log(`💥 Order ${orderId}: CPU-heavy task`);
      this.cpuIntensiveTask();
    } else if (chaosType < 0.35) {
      // 5% chance: Simulate worker crash
      console.log(`💀 Order ${orderId}: Simulating worker crash`);
      throw new Error(`Worker crashed processing order ${orderId}`);
    }
  }

  private cpuIntensiveTask(): void {
    // Intentionally block the event loop
    const start = Date.now();
    let result = 0;
    while (Date.now() - start < 500) {
      result += Math.sqrt(Math.random());
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  getQueueSize(): number {
    return this.queue.length;
  }

  getWorkerCount(): number {
    return this.workerCount;
  }
}

export const orderProcessor = new OrderProcessor();

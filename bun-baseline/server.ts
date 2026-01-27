/**
 * Bun Baseline Order Processing Server
 * Demonstrates traditional event-loop based concurrency
 */

import Fastify from 'fastify';
import { randomUUID } from 'crypto';
import { orderStore } from './order-store';
import { orderProcessor } from './order-processor';

const fastify = Fastify({
  logger: {
    level: 'info',
  },
});

// POST /orders - Create new order
fastify.post('/orders', async (request, reply) => {
  const orderId = randomUUID();
  const data = request.body;

  // Create order in store
  orderStore.create(orderId, data);

  // Enqueue for processing
  orderProcessor.enqueue(orderId, data);

  return {
    order_id: orderId,
    status: 'received',
  };
});

// GET /orders/:id - Get order status
fastify.get<{ Params: { id: string } }>('/orders/:id', async (request, reply) => {
  const { id } = request.params;
  const order = orderStore.get(id);

  if (!order) {
    reply.code(404);
    return { error: 'Order not found' };
  }

  return {
    order_id: order.id,
    status: order.status,
    created_at: order.createdAt,
    updated_at: order.updatedAt,
    retry_count: order.retryCount,
  };
});

// POST /chaos - Enable chaos mode
fastify.post('/chaos', async (request, reply) => {
  orderProcessor.enableChaos();
  
  return {
    message: 'Chaos mode enabled',
    warning: 'Random failures will now occur during order processing',
  };
});

// GET /health - Health check
fastify.get('/health', async (request, reply) => {
  return {
    status: 'ok',
    runtime: 'bun',
    queue_size: orderProcessor.getQueueSize(),
    active_workers: orderProcessor.getWorkerCount(),
  };
});

// GET /stats - System statistics
fastify.get('/stats', async (request, reply) => {
  const orders = orderStore.getAll();
  const stats = {
    total_orders: orders.length,
    received: orders.filter(o => o.status === 'received').length,
    processing: orders.filter(o => o.status === 'processing').length,
    completed: orders.filter(o => o.status === 'completed').length,
    failed: orders.filter(o => o.status === 'failed').length,
    queue_size: orderProcessor.getQueueSize(),
    active_workers: orderProcessor.getWorkerCount(),
  };

  return stats;
});

// Start server
const start = async () => {
  try {
    const port = parseInt(process.env.PORT || '3000');
    await fastify.listen({ port, host: '0.0.0.0' });
    console.log(`\n🚀 Bun Baseline Server running on http://localhost:${port}`);
    console.log(`📊 Stats: http://localhost:${port}/stats`);
    console.log(`💚 Health: http://localhost:${port}/health\n`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

import client from 'prom-client';

// Thu thập default metrics (CPU, memory, event loop, etc.)
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// HTTP request counter
export const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// HTTP request duration histogram
export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [register],
});

// Cache hit/miss counter
export const cacheCounter = new client.Counter({
  name: 'redis_cache_operations_total',
  help: 'Redis cache hits and misses',
  labelNames: ['result'], // 'hit' | 'miss'
  registers: [register],
});

// Crawl success/fail counter
export const crawlCounter = new client.Counter({
  name: 'crawl_operations_total',
  help: 'Crawl operations result',
  labelNames: ['status'], // 'success' | 'error'
  registers: [register],
});

export default register;

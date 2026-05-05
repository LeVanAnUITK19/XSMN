import Redis from 'ioredis';

// Enable TLS only for Upstash cloud (rediss://) — not for local Redis (redis://)
const isTLS = process.env.REDIS_URL?.startsWith('rediss://');
const redis = new Redis(process.env.REDIS_URL, isTLS ? { tls: {} } : {});

redis.on('connect', () => console.log('Redis connected'));
redis.on('error', (err) => console.error('Redis error:', err));

export default redis;

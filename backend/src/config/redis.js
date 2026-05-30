import Redis from 'ioredis';

export const redisConnect = async () => {
   try{
    const redis = new Redis(process.env.REDIS_URL);
    redis.on('connect', () => console.log('Redis connected'));
    redis.on('error', (err) => console.error('Redis error:', err));
    return redis;
   }
   catch(err){
    console.error('Failed to connect to Redis:', err);
    process.exit(1);
   }
};
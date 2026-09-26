import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { connectDB } from './src/config/db.js';
import resultRoutes from './src/routes/result_route.js';
import register from './src/monitoring/metrics.js';
import { metricsMiddleware, metricsAuthMiddleware } from './src/monitoring/metricsMiddleware.js';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// HTTP metrics middleware — phải đặt trước tất cả routes
// /metrics endpoint bị bỏ qua tự động bên trong middleware
app.use(metricsMiddleware);

// Kết nối DB
await connectDB(process.env.MONGODB_CONNECTIONSTRING);

// API routes
app.use('/api/results', resultRoutes);

// Prometheus scrape endpoint
// metricsAuthMiddleware kiểm tra METRICS_TOKEN nếu được set
app.get('/metrics', metricsAuthMiddleware, async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

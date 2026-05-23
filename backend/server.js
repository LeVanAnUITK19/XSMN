import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { connectDB } from './src/config/db.js';
import resultRoutes from './src/routes/result_route.js';
import register from './src/config/metrics.js';
import { httpRequestCounter, httpRequestDuration } from './src/config/metrics.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// Middleware đo HTTP metrics
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode,
    };
    httpRequestCounter.inc(labels);
    end(labels);
  });
  next();
});

await connectDB(process.env.MONGODB_CONNECTIONSTRING)
  .then(() => console.log('DB connected'))
  .catch(err => console.error(err));

app.use('/api/results', resultRoutes);

// Endpoint cho Prometheus scrape
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});

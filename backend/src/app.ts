import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth-routes';

const app = express();

app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/v1/auth', authRoutes);

// Healthcheck Route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Pulse Backend Server is Running' });
});

export default app;

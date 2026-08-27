import './config/crypto-polyfill';
import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth-routes';
import uploadRoutes from './routes/upload-routes';
import matchRoutes from './routes/match-routes';
import notificationRoutes from './routes/notification-routes';
import leaderboardRoutes from './routes/leaderboard-routes';
import communityRoutes from './routes/community-routes';
import publicRoutes from './routes/public-routes';

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Public Web Pages (Play Store Policy & Privacy Compliance)
app.use('/', publicRoutes);

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/matches', matchRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/leaderboard', leaderboardRoutes);
app.use('/api/v1/community', communityRoutes);

// Healthcheck Route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Pulse Backend Server is Running' });
});

export default app;

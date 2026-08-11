import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import './config/crypto-polyfill';
import app from './app';
import { config } from './config/env';
import { initMatchSockets } from './sockets/match-socket';
import { setSocketIOInstance } from './sockets/socket-emitter';

const server = http.createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: '*',
  },
});

setSocketIOInstance(io);
initMatchSockets(io);

server.listen(config.port, () => {
  console.log(`🚀 Pulse Backend running at http://localhost:${config.port}`);
  try {
    const admin = require('firebase-admin');
    if (!admin.apps || !admin.apps.length) {
      admin.initializeApp();
    }
    (global as any).firebaseAdmin = admin;
    console.log('Firebase Admin SDK initialized for FCM push notifications');
  } catch (_) {
    console.log('Firebase Admin SDK fallback mode active (FcmService ready)');
  }
});


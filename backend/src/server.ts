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
      let serviceAccount;
      try {
        serviceAccount = require('../firebase-service-account.json/pulse-6bec2-firebase-adminsdk-fbsvc-d0cf5805b2.json');
      } catch (_) {
        try {
          serviceAccount = require('../firebase-service-account.json');
        } catch (_) {}
      }

      if (serviceAccount) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        console.log('Firebase Admin SDK initialized with Firebase Service Account Key credentials!');
      } else {
        admin.initializeApp();
        console.log('Firebase Admin SDK initialized (default environment)');
      }
    }
    (global as any).firebaseAdmin = admin;
  } catch (err) {
    console.log('Firebase Admin SDK fallback mode active (FcmService ready):', err);
  }
});


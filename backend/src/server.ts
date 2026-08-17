import http from 'http';
import * as admin from 'firebase-admin';
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

import fs from 'fs';

function initializeFirebaseAdmin(): void {
  try {
    if (!admin.apps.length) {
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

      if (serviceAccountJson) {
        if (serviceAccountJson.trim().startsWith('{')) {
          admin.initializeApp({
            credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
          });
          console.log('Firebase Admin SDK initialized with raw FIREBASE_SERVICE_ACCOUNT_JSON string.');
        } else if (fs.existsSync(serviceAccountJson)) {
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccountJson),
          });
          console.log(`Firebase Admin SDK initialized with service account file at: ${serviceAccountJson}`);
        }
      } else if (credentialsPath && fs.existsSync(credentialsPath)) {
        admin.initializeApp({
          credential: admin.credential.cert(credentialsPath),
        });
        console.log(`Firebase Admin SDK initialized with GOOGLE_APPLICATION_CREDENTIALS at: ${credentialsPath}`);
      } else {
        admin.initializeApp();
        console.log('Firebase Admin SDK initialized with default application credentials.');
      }
    }
    (global as any).firebaseAdmin = admin;
  } catch (err) {
    console.error('Firebase Admin SDK unavailable. FCM notifications will not be sent:', err);
  }
}

initializeFirebaseAdmin();

server.listen(config.port, () => {
  console.log(`🚀 Pulse Backend running at http://localhost:${config.port}`);
});


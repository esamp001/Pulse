import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import './config/crypto-polyfill';
import app from './app';
import { config } from './config/env';
import { initMatchSockets } from './sockets/match-socket';

const server = http.createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: '*',
  },
});

initMatchSockets(io);

server.listen(config.port, () => {
  console.log(`🚀 Pulse Backend running at http://localhost:${config.port}`);
});


import { Server, Socket } from 'socket.io';
import { notifyUserActiveMatchUpdate } from './socket-emitter';

interface LiveMatchScore {
  p1Score: number;
  p2Score: number;
  currentSet: number;
  player: 'P1' | 'P2';
  setScores: string;
}

const liveScores = new Map<string, LiveMatchScore>();

export function initMatchSockets(io: Server): void {
  io.on('connection', (socket: Socket) => {
    console.log(`Socket connected: ${socket.id}`);

    // Join personal user room
    socket.on('join_user', (data: { userId: string }) => {
      if (data?.userId) {
        const room = `user:${data.userId}`;
        socket.join(room);
      }
    });

    // Leave personal user room
    socket.on('leave_user', (data: { userId: string }) => {
      if (data?.userId) {
        const room = `user:${data.userId}`;
        socket.leave(room);
      }
    });

    // Join match room
    socket.on('join_match', (data: { matchId: string; userId?: string; role?: string }) => {
      const room = `match:${data.matchId}`;
      socket.join(room);
      console.log(`[MatchSocket] Socket ${socket.id} (user: ${data.userId}, role: ${data.role}) joined ${room}`);
      
      io.to(room).emit('user_joined_match', {
        userId: data.userId,
        role: data.role,
        timestamp: new Date().toISOString(),
      });

      // Synchronize live score snapshot to newly joined user (Player 1, Player 2, Spectator)
      const cached = liveScores.get(data.matchId);
      if (cached) {
        socket.emit('score_updated', {
          matchId: data.matchId,
          player: cached.player,
          p1Score: cached.p1Score,
          p2Score: cached.p2Score,
          currentSet: cached.currentSet,
          setScores: cached.setScores,
          action: 'SYNC',
          timestamp: new Date().toISOString(),
        });
      }
    });

    // Leave match room
    socket.on('leave_match', (data: { matchId: string }) => {
      const room = `match:${data.matchId}`;
      socket.leave(room);
    });

    // Scorer starts match (READY -> LIVE)
    socket.on('start_match', (data: { matchId: string }) => {
      const room = `match:${data.matchId}`;
      
      io.to(room).emit('match_status_changed', {
        matchId: data.matchId,
        status: 'LIVE',
        timestamp: new Date().toISOString(),
      });
      notifyUserActiveMatchUpdate();
    });

    // Scorer records a point for Player 1 or Player 2
    socket.on('record_point', (data: { matchId: string; player: 'P1' | 'P2'; p1Score: number; p2Score: number; currentSet: number; setScores?: string }, callback?: Function) => {
      const room = `match:${data.matchId}`;
      liveScores.set(data.matchId, {
        p1Score: data.p1Score,
        p2Score: data.p2Score,
        currentSet: data.currentSet,
        player: data.player,
        setScores: data.setScores || '',
      });

      io.to(room).emit('score_updated', {
        matchId: data.matchId,
        player: data.player,
        p1Score: data.p1Score,
        p2Score: data.p2Score,
        currentSet: data.currentSet,
        setScores: data.setScores || '',
        action: 'POINT',
        timestamp: new Date().toISOString(),
      });

      if (typeof callback === 'function') {
        callback({ success: true, timestamp: new Date().toISOString() });
      }
    });

    // Scorer undos last point
    socket.on('undo_point', (data: { matchId: string; p1Score: number; p2Score: number; currentSet: number; setScores?: string }, callback?: Function) => {
      const room = `match:${data.matchId}`;
      const existing = liveScores.get(data.matchId);
      liveScores.set(data.matchId, {
        p1Score: data.p1Score,
        p2Score: data.p2Score,
        currentSet: data.currentSet,
        player: existing?.player || 'P1',
        setScores: data.setScores || '',
      });

      io.to(room).emit('score_updated', {
        matchId: data.matchId,
        p1Score: data.p1Score,
        p2Score: data.p2Score,
        currentSet: data.currentSet,
        setScores: data.setScores || '',
        action: 'UNDO',
        timestamp: new Date().toISOString(),
      });

      if (typeof callback === 'function') {
        callback({ success: true, timestamp: new Date().toISOString() });
      }
    });

    // Scorer completes match
    socket.on('match_completed', (data: { matchId: string; winnerId: string; ratingChange?: number; p1SetsWon?: number; p2SetsWon?: number }) => {
      const room = `match:${data.matchId}`;
      liveScores.delete(data.matchId);

      io.to(room).emit('match_completed', {
        matchId: data.matchId,
        winnerId: data.winnerId,
        ratingChange: data.ratingChange || 25,
        p1SetsWon: data.p1SetsWon || 0,
        p2SetsWon: data.p2SetsWon || 0,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
}

import { Server } from 'socket.io';

let ioInstance: Server | null = null;

export function setSocketIOInstance(io: Server): void {
  ioInstance = io;
}

export function getSocketIOInstance(): Server | null {
  return ioInstance;
}

/**
 * Notify specific user(s) or broadcast that active match state has changed.
 * If userIds is provided and non-empty, emits to user:<id> rooms.
 * If userIds is omitted or empty, broadcasts to all connected sockets.
 */
export function notifyUserActiveMatchUpdate(userIds?: (string | null | undefined)[]): void {
  if (!ioInstance) return;

  const eventPayload = {
    type: 'ACTIVE_MATCH_UPDATED',
    timestamp: new Date().toISOString(),
  };

  const validUserIds = Array.from(
    new Set((userIds || []).filter((id): id is string => typeof id === 'string' && id.trim().length > 0))
  );

  if (validUserIds.length > 0) {
    validUserIds.forEach((userId) => {
      ioInstance?.to(`user:${userId}`).emit('active_match_updated', eventPayload);
    });
  } else {
    ioInstance.emit('active_match_updated', eventPayload);
  }
}

import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../database/db';
import { config } from '../config';

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, config.auth.bcryptRounds);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function generateToken(userId: string): string {
  return jwt.sign({ userId }, config.auth.jwtSecret, {
    expiresIn: config.auth.jwtExpiresIn
  });
}

export async function verifyToken(token: string): Promise<any> {
  try {
    return jwt.verify(token, config.auth.jwtSecret);
  } catch (error) {
    return null;
  }
}

export async function createSession(userId: string): Promise<{ token: string; expiresAt: string }> {
  const db = getDb();
  const token = generateToken(userId);
  const sessionId = uuidv4();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24 hours

  db.prepare(`
    INSERT INTO sessions (id, user_id, token, expires_at)
    VALUES (?, ?, ?, ?)
  `).run(sessionId, userId, token, expiresAt);

  return { token, expiresAt };
}

export async function invalidateSession(token: string): Promise<void> {
  const db = getDb();
  db.prepare('DELETE FROM sessions WHERE token = ?').run(token);
}

export async function cleanupExpiredSessions(): Promise<void> {
  const db = getDb();
  db.prepare('DELETE FROM sessions WHERE expires_at < datetime("now")').run();
}
import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import Joi from 'joi';
import { getDb } from '../database/db';
import { hashPassword, verifyPassword, createSession, invalidateSession } from '../services/auth';
import { validateRequest } from '../middleware/validation';
import { logger } from '../index';

const router = Router();

const registerSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required()
});

const loginSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required()
});

// POST /api/auth/register
router.post('/register', validateRequest(registerSchema), async (req, res) => {
  try {
    const db = getDb();
    const { username, email, password } = req.body;

    // Check if user exists
    const existing = db.prepare(
      'SELECT id FROM users WHERE username = ? OR email = ?'
    ).get(username, email);

    if (existing) {
      return res.status(400).json({ error: 'Username or email already exists' });
    }

    // Create user
    const userId = uuidv4();
    const passwordHash = await hashPassword(password);

    db.prepare(`
      INSERT INTO users (id, username, email, password_hash, role)
      VALUES (?, ?, ?, ?, 'user')
    `).run(userId, username, email, passwordHash);

    // Create session
    const session = await createSession(userId);

    res.status(201).json({
      user: {
        id: userId,
        username,
        email,
        role: 'user'
      },
      token: session.token,
      expiresAt: session.expiresAt
    });
  } catch (error) {
    logger.error('Registration failed:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', validateRequest(loginSchema), async (req, res) => {
  try {
    const db = getDb();
    const { username, password } = req.body;

    // Find user
    const user = db.prepare(`
      SELECT id, username, email, password_hash, role
      FROM users
      WHERE username = ? OR email = ?
    `).get(username, username) as any;

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const valid = await verifyPassword(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Create session
    const session = await createSession(user.id);

    res.json({
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      },
      token: session.token,
      expiresAt: session.expiresAt
    });
  } catch (error) {
    logger.error('Login failed:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST /api/auth/logout
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (token) {
      await invalidateSession(token);
    }
    res.status(204).send();
  } catch (error) {
    logger.error('Logout failed:', error);
    res.status(500).json({ error: 'Logout failed' });
  }
});

// GET /api/auth/me
router.get('/me', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const db = getDb();
    const session = db.prepare(`
      SELECT s.*, u.id, u.username, u.email, u.role
      FROM sessions s
      JOIN users u ON s.user_id = u.id
      WHERE s.token = ? AND s.expires_at > datetime('now')
    `).get(token) as any;

    if (!session) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }

    res.json({
      user: {
        id: session.id,
        username: session.username,
        email: session.email,
        role: session.role
      }
    });
  } catch (error) {
    logger.error('Failed to get user info:', error);
    res.status(500).json({ error: 'Failed to get user info' });
  }
});

export const authRoutes = router;
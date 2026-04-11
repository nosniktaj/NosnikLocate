require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, param, validationResult } = require('express-validator');

const pool = require('./db/pool');
const authenticate = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});
app.use(limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many authentication attempts, please try again later.' },
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

function generateToken(user) {
  return jwt.sign(
    { id: user.id, username: user.username },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// ---------------------------------------------------------------------------
// Health check
// ---------------------------------------------------------------------------
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ===========================================================================
// AUTH ROUTES
// ===========================================================================

// POST /api/auth/register
app.post(
  '/api/auth/register',
  authLimiter,
  [
    body('username')
      .trim()
      .isLength({ min: 3, max: 50 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Username must be 3-50 alphanumeric characters or underscores'),
    body('email').isEmail().normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters'),
    body('display_name').optional().trim().isLength({ max: 100 }),
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { username, email, password, display_name } = req.body;
      const passwordHash = await bcrypt.hash(password, 12);

      const result = await pool.query(
        `INSERT INTO users (username, email, password_hash, display_name)
         VALUES ($1, $2, $3, $4)
         RETURNING id, username, email, display_name, created_at`,
        [username, email, passwordHash, display_name || null]
      );

      const user = result.rows[0];

      // Create default settings for the new user
      await pool.query(
        `INSERT INTO user_settings (user_id) VALUES ($1)`,
        [user.id]
      );

      const token = generateToken(user);

      res.status(201).json({
        message: 'User registered successfully',
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          display_name: user.display_name,
        },
        token,
      });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Username or email already exists' });
      }
      console.error('Registration error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// POST /api/auth/login
app.post(
  '/api/auth/login',
  authLimiter,
  [
    body('username').trim().notEmpty(),
    body('password').notEmpty(),
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { username, password } = req.body;

      const result = await pool.query(
        `SELECT id, username, email, password_hash, display_name, is_active
         FROM users WHERE username = $1`,
        [username]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const user = result.rows[0];

      if (!user.is_active) {
        return res.status(403).json({ error: 'Account is deactivated' });
      }

      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      await pool.query(
        `UPDATE users SET last_login = NOW() WHERE id = $1`,
        [user.id]
      );

      const token = generateToken(user);

      res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          display_name: user.display_name,
        },
        token,
      });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// POST /api/auth/logout
app.post('/api/auth/logout', authenticate, (_req, res) => {
  // With stateless JWT the client simply discards the token.
  // A Redis-backed token blacklist can be added here for immediate
  // invalidation if required.
  res.json({ message: 'Logged out successfully' });
});

// ===========================================================================
// USER ROUTES
// ===========================================================================

// GET /api/user/profile
app.get('/api/user/profile', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, email, display_name, avatar_url, created_at, last_login
       FROM users WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error('Profile fetch error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/user/profile
app.put(
  '/api/user/profile',
  authenticate,
  [
    body('display_name').optional().trim().isLength({ max: 100 }),
    body('email').optional().isEmail().normalizeEmail(),
    body('avatar_url').optional().isURL(),
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const fields = [];
      const values = [];
      let idx = 1;

      for (const key of ['display_name', 'email', 'avatar_url']) {
        if (req.body[key] !== undefined) {
          fields.push(`${key} = $${idx}`);
          values.push(req.body[key]);
          idx++;
        }
      }

      if (fields.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      fields.push(`updated_at = NOW()`);
      values.push(req.user.id);

      const result = await pool.query(
        `UPDATE users SET ${fields.join(', ')} WHERE id = $${idx}
         RETURNING id, username, email, display_name, avatar_url, updated_at`,
        values
      );

      res.json({ user: result.rows[0] });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Email already in use' });
      }
      console.error('Profile update error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// PUT /api/user/password
app.put(
  '/api/user/password',
  authenticate,
  [
    body('current_password').notEmpty(),
    body('new_password')
      .isLength({ min: 8 })
      .withMessage('New password must be at least 8 characters'),
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { current_password, new_password } = req.body;

      const result = await pool.query(
        `SELECT password_hash FROM users WHERE id = $1`,
        [req.user.id]
      );

      const valid = await bcrypt.compare(current_password, result.rows[0].password_hash);
      if (!valid) {
        return res.status(401).json({ error: 'Current password is incorrect' });
      }

      const newHash = await bcrypt.hash(new_password, 12);
      await pool.query(
        `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
        [newHash, req.user.id]
      );

      res.json({ message: 'Password updated successfully' });
    } catch (err) {
      console.error('Password change error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// DELETE /api/user/account
app.delete('/api/user/account', authenticate, async (req, res) => {
  try {
    await pool.query(`DELETE FROM users WHERE id = $1`, [req.user.id]);
    res.json({ message: 'Account deleted successfully' });
  } catch (err) {
    console.error('Account deletion error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ===========================================================================
// LOCATION ROUTES
// ===========================================================================

// POST /api/location/update
app.post(
  '/api/location/update',
  authenticate,
  [
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('accuracy').optional().isFloat({ min: 0 }),
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { latitude, longitude, accuracy } = req.body;

      const result = await pool.query(
        `INSERT INTO user_locations (user_id, location, accuracy)
         VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography, $4)
         RETURNING id, timestamp`,
        [req.user.id, longitude, latitude, accuracy || null]
      );

      res.json({
        message: 'Location updated',
        location: {
          id: result.rows[0].id,
          latitude,
          longitude,
          accuracy,
          timestamp: result.rows[0].timestamp,
        },
      });
    } catch (err) {
      console.error('Location update error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// GET /api/location/friends
app.get('/api/location/friends', authenticate, async (req, res) => {
  try {
    const staleMinutes = parseInt(process.env.LOCATION_STALE_MINUTES, 10) || 30;
    const nearbyMeters = parseInt(process.env.NEARBY_DISTANCE_METERS, 10) || 50000;

    // Get latest location for each accepted friend, within staleness window
    const result = await pool.query(
      `SELECT DISTINCT ON (u.id)
              u.id,
              u.username,
              u.display_name,
              u.avatar_url,
              ST_Y(ul.location::geometry) AS latitude,
              ST_X(ul.location::geometry) AS longitude,
              ul.accuracy,
              ul.timestamp,
              us.share_location
       FROM users u
       INNER JOIN friendships f
         ON (f.requester_id = u.id OR f.addressee_id = u.id)
         AND (f.requester_id = $1 OR f.addressee_id = $1)
         AND f.status = 'accepted'
       INNER JOIN user_locations ul ON ul.user_id = u.id
       INNER JOIN user_settings us ON us.user_id = u.id
       WHERE u.id != $1
         AND us.share_location = TRUE
         AND ul.timestamp > NOW() - INTERVAL '1 minute' * $2
       ORDER BY u.id, ul.timestamp DESC`,
      [req.user.id, staleMinutes]
    );

    res.json({ friends: result.rows });
  } catch (err) {
    console.error('Friends location error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ===========================================================================
// FRIENDS ROUTES
// ===========================================================================

// GET /api/friends
app.get('/api/friends', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         f.id AS friendship_id,
         CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END AS friend_id,
         u.username,
         u.display_name,
         u.avatar_url,
         f.created_at
       FROM friendships f
       INNER JOIN users u
         ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
       WHERE (f.requester_id = $1 OR f.addressee_id = $1)
         AND f.status = 'accepted'
       ORDER BY u.display_name, u.username`,
      [req.user.id]
    );

    res.json({ friends: result.rows });
  } catch (err) {
    console.error('Friends list error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/friends/request
app.post(
  '/api/friends/request',
  authenticate,
  [body('username').trim().notEmpty()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { username } = req.body;

      const userResult = await pool.query(
        `SELECT id FROM users WHERE username = $1`,
        [username]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const addresseeId = userResult.rows[0].id;

      if (addresseeId === req.user.id) {
        return res.status(400).json({ error: 'Cannot send a friend request to yourself' });
      }

      // Check for existing friendship in either direction
      const existing = await pool.query(
        `SELECT id, status FROM friendships
         WHERE (requester_id = $1 AND addressee_id = $2)
            OR (requester_id = $2 AND addressee_id = $1)`,
        [req.user.id, addresseeId]
      );

      if (existing.rows.length > 0) {
        const status = existing.rows[0].status;
        if (status === 'accepted') {
          return res.status(409).json({ error: 'Already friends' });
        }
        if (status === 'pending') {
          return res.status(409).json({ error: 'Friend request already pending' });
        }
        if (status === 'blocked') {
          return res.status(403).json({ error: 'Unable to send friend request' });
        }
      }

      const result = await pool.query(
        `INSERT INTO friendships (requester_id, addressee_id)
         VALUES ($1, $2)
         RETURNING id, status, created_at`,
        [req.user.id, addresseeId]
      );

      res.status(201).json({
        message: 'Friend request sent',
        request: result.rows[0],
      });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Friend request already exists' });
      }
      console.error('Friend request error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// PUT /api/friends/request/:id/accept
app.put(
  '/api/friends/request/:id/accept',
  authenticate,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const result = await pool.query(
        `UPDATE friendships
         SET status = 'accepted', updated_at = NOW()
         WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
         RETURNING id, requester_id, status, updated_at`,
        [req.params.id, req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pending friend request not found' });
      }

      res.json({ message: 'Friend request accepted', friendship: result.rows[0] });
    } catch (err) {
      console.error('Accept request error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// PUT /api/friends/request/:id/reject
app.put(
  '/api/friends/request/:id/reject',
  authenticate,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const result = await pool.query(
        `UPDATE friendships
         SET status = 'rejected', updated_at = NOW()
         WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
         RETURNING id, status, updated_at`,
        [req.params.id, req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pending friend request not found' });
      }

      res.json({ message: 'Friend request rejected', friendship: result.rows[0] });
    } catch (err) {
      console.error('Reject request error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// DELETE /api/friends/:id
app.delete(
  '/api/friends/:id',
  authenticate,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const result = await pool.query(
        `DELETE FROM friendships
         WHERE id = $1
           AND (requester_id = $2 OR addressee_id = $2)
           AND status = 'accepted'
         RETURNING id`,
        [req.params.id, req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Friendship not found' });
      }

      res.json({ message: 'Friend removed' });
    } catch (err) {
      console.error('Remove friend error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

// GET /api/friends/requests/pending
app.get('/api/friends/requests/pending', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT f.id, u.id AS user_id, u.username, u.display_name, u.avatar_url, f.created_at
       FROM friendships f
       INNER JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );

    res.json({ requests: result.rows });
  } catch (err) {
    console.error('Pending requests error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// 404 handler
// ---------------------------------------------------------------------------
app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// ---------------------------------------------------------------------------
// Global error handler
// ---------------------------------------------------------------------------
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ---------------------------------------------------------------------------
// Start server
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
  console.log(`NosnikLocate API server running on port ${PORT}`);
});

module.exports = app;

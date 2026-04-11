# NosnikLocate Server Setup Guide

This document provides step-by-step instructions for deploying the NosnikLocate backend
server on a fresh Linux system. Follow each section in order to go from a bare machine to
a fully operational, production-ready API.

---

## Overview

NosnikLocate uses a three-tier architecture:

```
┌──────────────────┐       HTTPS        ┌─────────────────────┐        ┌────────────────┐
│  Qt/C++ Mobile   │  ───────────────►  │  REST API Server    │  ────► │  PostgreSQL +  │
│  Application     │  ◄───────────────  │  (Node.js/Express)  │  ◄──── │  PostGIS       │
└──────────────────┘    JSON responses  └─────────────────────┘        └────────────────┘
                                                 │
                                                 ▼
                                         ┌──────────────┐
                                         │    Redis      │
                                         │  (sessions)   │
                                         └──────────────┘
```

**Core principles:**

- All components are **free and open-source software (FOSS)**.
- **No user data is sold to third parties.** All data stays on your own server.
- The mobile client communicates exclusively through the REST API over HTTPS.

**Technology stack and licenses:**

| Component               | License            | Purpose                                |
|--------------------------|--------------------|----------------------------------------|
| Node.js with Express     | MIT                | REST API server                        |
| PostgreSQL               | PostgreSQL License | Relational database                    |
| PostGIS                  | GPLv2              | Geospatial queries (geography types)   |
| Redis                    | BSD License        | Session store and caching              |
| Nginx                    | BSD-2-Clause       | Reverse proxy and TLS termination      |

---

## Prerequisites

Before you begin, make sure you have access to a server (physical or virtual) that meets
the following minimum requirements:

| Requirement        | Minimum                          |
|--------------------|----------------------------------|
| Operating System   | Ubuntu 22.04 LTS or newer        |
| Node.js            | 18.x or newer (LTS recommended)  |
| PostgreSQL         | 15 or newer                      |
| PostGIS            | 3.3+ (matching your PG version)  |
| Redis              | 7.0 or newer                     |
| Nginx              | Latest from Ubuntu repos         |
| SSL                | Let's Encrypt via Certbot        |
| Firewall           | UFW (Uncomplicated Firewall)     |
| RAM                | 1 GB minimum, 2 GB recommended   |
| Disk               | 20 GB minimum                    |

You will also need a **domain name** pointed at your server's public IP address for the
SSL certificate step.

---

## Step 1: System Setup

### 1.1 Update system packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install essential build tools

```bash
sudo apt install -y build-essential curl wget git ca-certificates gnupg lsb-release
```

### 1.3 Configure the UFW firewall

```bash
# Enable UFW (if not already active)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH so you don't lock yourself out
sudo ufw allow OpenSSH

# Allow HTTP and HTTPS for the web server
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable the firewall
sudo ufw enable

# Verify the rules
sudo ufw status verbose
```

> **Important:** Do **not** expose port 3000 (the Node.js app), port 5432 (PostgreSQL),
> or port 6379 (Redis) to the public internet. They are only accessed via `localhost`.

---

## Step 2: PostgreSQL and PostGIS

### 2.1 Install PostgreSQL 15+ and PostGIS

```bash
# Add the official PostgreSQL APT repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor \
  -o /etc/apt/trusted.gpg.d/postgresql.gpg

sudo apt update
sudo apt install -y postgresql-15 postgresql-15-postgis-3
```

### 2.2 Create the database user and database

```bash
sudo -u postgres psql <<'EOF'
-- Create the application user (change the password!)
CREATE USER nosniklocate_user WITH ENCRYPTED PASSWORD 'CHANGE_ME_TO_A_STRONG_PASSWORD';

-- Create the database owned by that user
CREATE DATABASE nosniklocate OWNER nosniklocate_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE nosniklocate TO nosniklocate_user;
EOF
```

### 2.3 Enable PostGIS and uuid-ossp extensions

```bash
sudo -u postgres psql -d nosniklocate <<'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
EOF
```

### 2.4 Apply the full database schema

Connect to the `nosniklocate` database and run the following SQL. This is the complete
schema from `server/src/db/schema.sql`:

```sql
-- ============================================================
-- NosnikLocate Database Schema
-- PostgreSQL 15+ with PostGIS extension
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- Users table
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username        VARCHAR(50) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100),
    avatar_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_login      TIMESTAMPTZ
);

-- ============================================================
-- User locations table (PostGIS geography for spatial queries)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_locations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy        DOUBLE PRECISION,
    timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

-- ============================================================
-- Friendships table
-- ============================================================
CREATE TABLE IF NOT EXISTS friendships (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id    UUID NOT NULL,
    addressee_id    UUID NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_requester
        FOREIGN KEY (requester_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_addressee
        FOREIGN KEY (addressee_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_friendship
        UNIQUE (requester_id, addressee_id)
);

-- ============================================================
-- User settings table
-- ============================================================
CREATE TABLE IF NOT EXISTS user_settings (
    user_id                 UUID PRIMARY KEY,
    share_location          BOOLEAN NOT NULL DEFAULT TRUE,
    update_interval         INT NOT NULL DEFAULT 30000,
    notifications_enabled   BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_settings_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

-- ============================================================
-- Indexes for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id
    ON user_locations (user_id);

CREATE INDEX IF NOT EXISTS idx_user_locations_timestamp
    ON user_locations (timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_user_locations_user_timestamp
    ON user_locations (user_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_friendships_requester
    ON friendships (requester_id);

CREATE INDEX IF NOT EXISTS idx_friendships_addressee
    ON friendships (addressee_id);

CREATE INDEX IF NOT EXISTS idx_friendships_status
    ON friendships (status);

CREATE INDEX IF NOT EXISTS idx_friendships_requester_status
    ON friendships (requester_id, status);

CREATE INDEX IF NOT EXISTS idx_friendships_addressee_status
    ON friendships (addressee_id, status);

-- Spatial index on user locations
CREATE INDEX IF NOT EXISTS idx_user_locations_gist
    ON user_locations USING GIST (location);
```

You can also apply the schema directly from the source file:

```bash
sudo -u postgres psql -d nosniklocate -f /opt/nosniklocate/server/src/db/schema.sql
```

### 2.5 Verify the installation

```bash
sudo -u postgres psql -d nosniklocate -c "\dt"
```

You should see four tables: `users`, `user_locations`, `friendships`, and `user_settings`.

---

## Step 3: Redis Setup

### 3.1 Install Redis 7+

```bash
# Add the official Redis APT repository
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor \
  -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] \
  https://packages.redis.io/deb $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis-server
```

### 3.2 Configure password authentication

Edit the Redis configuration:

```bash
sudo nano /etc/redis/redis.conf
```

Find and set the following directives:

```ini
# Bind to localhost only (never expose Redis to the public internet)
bind 127.0.0.1 -::1

# Require a password for all commands
requirepass CHANGE_ME_TO_A_STRONG_PASSWORD

# Disable dangerous commands in production
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG ""
```

### 3.3 Enable persistence

In the same `redis.conf`, make sure RDB snapshots and AOF are enabled:

```ini
# RDB snapshots (default is fine for most setups)
save 900 1
save 300 10
save 60 10000

# Append-only file for durability
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
```

### 3.4 Restart and verify

```bash
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Test authentication
redis-cli -a 'CHANGE_ME_TO_A_STRONG_PASSWORD' ping
# Expected output: PONG
```

---

## Step 4: Node.js API Server

### 4.1 Install Node.js 18+ via NodeSource

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify the installation
node --version   # Should be v18.x or newer
npm --version
```

### 4.2 Create the application directory

```bash
sudo mkdir -p /opt/nosniklocate
sudo chown $USER:$USER /opt/nosniklocate
```

### 4.3 Copy server files

```bash
# From the repository root
cp -r server/* /opt/nosniklocate/
```

### 4.4 Install dependencies

```bash
cd /opt/nosniklocate
npm install --production
```

This installs the following dependencies (from `package.json`):

| Package              | Version  | Purpose                                |
|----------------------|----------|----------------------------------------|
| bcrypt               | ^5.1.1   | Password hashing (cost factor 12)      |
| cors                 | ^2.8.5   | Cross-origin resource sharing          |
| dotenv               | ^16.3.1  | Environment variable management        |
| express              | ^4.18.2  | HTTP server framework                  |
| express-rate-limit   | ^7.1.4   | Application-level rate limiting        |
| express-validator    | ^7.0.1   | Input validation and sanitization      |
| helmet               | ^7.1.0   | Security headers                       |
| jsonwebtoken         | ^9.0.2   | JWT creation and verification          |
| pg                   | ^8.11.3  | PostgreSQL client                      |
| redis                | ^4.6.10  | Redis client for session management    |
| uuid                 | ^9.0.0   | UUID generation                        |

### 4.5 Configure environment variables

```bash
cp .env.example .env
nano .env
```

Fill in the real values. Here is the full template with explanations:

```bash
# ====================
# Server Configuration
# ====================
PORT=3000
NODE_ENV=production

# ====================
# PostgreSQL Database
# ====================
DB_HOST=localhost
DB_PORT=5432
DB_NAME=nosniklocate
DB_USER=nosniklocate_user
DB_PASSWORD=your_real_postgres_password_here

# ====================
# Redis
# ====================
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_real_redis_password_here

# ====================
# JWT Authentication
# ====================
# Generate with: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=your_64_byte_hex_secret_here
JWT_EXPIRES_IN=7d

# ====================
# Rate Limiting
# ====================
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# ====================
# CORS
# ====================
CORS_ORIGIN=*

# ====================
# Location Settings
# ====================
NEARBY_DISTANCE_METERS=50000
LOCATION_STALE_MINUTES=30
```

> **Security tip:** Generate a strong JWT secret with:
> ```bash
> node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
> ```

### 4.6 Directory structure

The server source tree is organized as follows:

```
server/
├── package.json          # Dependencies and npm scripts
├── .env.example          # Environment variable template
└── src/
    ├── server.js         # Main Express application with all REST endpoints
    ├── middleware/
    │   └── auth.js       # JWT authentication middleware
    └── db/
        ├── pool.js       # PostgreSQL connection pool (max 20 connections)
        └── schema.sql    # Full database schema with PostGIS support
```

- **`server.js`** — The main entry point. Configures Express middleware (Helmet, CORS,
  rate limiting, JSON parsing) and defines all 16 REST endpoints.
- **`middleware/auth.js`** — Extracts the `Bearer` token from the `Authorization` header,
  verifies it with `jsonwebtoken`, and attaches the decoded user payload to `req.user`.
- **`db/pool.js`** — Creates a connection pool (`pg.Pool`) with a maximum of 20
  connections, 30 s idle timeout, and 2 s connection timeout.
- **`db/schema.sql`** — The complete PostgreSQL schema including PostGIS extensions,
  tables, constraints, and indexes.

### 4.7 Available API endpoints

The server exposes the following 16 endpoints:

| #  | Method   | Path                                | Auth Required | Description                            |
|----|----------|-------------------------------------|---------------|----------------------------------------|
| 1  | `POST`   | `/api/auth/register`                | No            | Create a new user account              |
| 2  | `POST`   | `/api/auth/login`                   | No            | Authenticate and receive a JWT         |
| 3  | `POST`   | `/api/auth/logout`                  | Yes           | Log out (client discards token)        |
| 4  | `GET`    | `/api/user/profile`                 | Yes           | Get the current user's profile         |
| 5  | `PUT`    | `/api/user/profile`                 | Yes           | Update display name, email, avatar     |
| 6  | `PUT`    | `/api/user/password`                | Yes           | Change password                        |
| 7  | `DELETE` | `/api/user/account`                 | Yes           | Permanently delete account and data    |
| 8  | `POST`   | `/api/location/update`              | Yes           | Submit a new location point            |
| 9  | `GET`    | `/api/location/friends`             | Yes           | Get latest locations of friends        |
| 10 | `GET`    | `/api/friends`                      | Yes           | List all accepted friends              |
| 11 | `POST`   | `/api/friends/request`              | Yes           | Send a friend request by username      |
| 12 | `PUT`    | `/api/friends/request/:id/accept`   | Yes           | Accept a pending friend request        |
| 13 | `PUT`    | `/api/friends/request/:id/reject`   | Yes           | Reject a pending friend request        |
| 14 | `DELETE` | `/api/friends/:id`                  | Yes           | Remove an accepted friend              |
| 15 | `GET`    | `/api/friends/requests/pending`     | Yes           | List incoming pending friend requests  |
| 16 | `GET`    | `/api/health`                       | No            | Health check (returns `{ status: ok }`) |

### 4.8 Quick smoke test

```bash
cd /opt/nosniklocate
node src/server.js &

# Health check
curl -s http://localhost:3000/api/health | python3 -m json.tool

# Stop the background process when done
kill %1
```

Expected response:

```json
{
    "status": "ok",
    "timestamp": "2024-01-15T12:00:00.000Z"
}
```

---

## Step 5: Nginx Reverse Proxy

### 5.1 Install Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
```

### 5.2 Create the site configuration

```bash
sudo nano /etc/nginx/sites-available/nosniklocate
```

Paste the following configuration:

```nginx
# Rate limiting zone: 10 requests per second per IP
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

upstream nosniklocate_api {
    server 127.0.0.1:3000;
    keepalive 64;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.example.com;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.example.com;

    # SSL certificates (managed by Certbot)
    ssl_certificate     /etc/letsencrypt/live/your-domain.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.example.com/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'none'; frame-ancestors 'none'" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Request size limit
    client_max_body_size 1m;

    # API proxy
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;

        proxy_pass http://nosniklocate_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Block everything that isn't /api/
    location / {
        return 404;
    }
}
```

### 5.3 Enable the site

```bash
sudo ln -s /etc/nginx/sites-available/nosniklocate /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test the configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 5.4 Obtain an SSL certificate with Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx

# Obtain the certificate (replace with your real domain)
sudo certbot --nginx -d your-domain.example.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

Certbot will automatically update the Nginx configuration with the correct certificate
paths and set up a systemd timer for renewal.

---

## Step 6: Systemd Service

### 6.1 Create a dedicated system user

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin nosniklocate
sudo chown -R nosniklocate:nosniklocate /opt/nosniklocate
```

### 6.2 Create the service file

```bash
sudo nano /etc/systemd/system/nosniklocate.service
```

Paste the following:

```ini
[Unit]
Description=NosnikLocate API Server
Documentation=https://github.com/Nosniktaj/NosnikLocate
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=nosniklocate
Group=nosniklocate
WorkingDirectory=/opt/nosniklocate
ExecStart=/usr/bin/node src/server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nosniklocate

# Environment
Environment=NODE_ENV=production
EnvironmentFile=/opt/nosniklocate/.env

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/nosniklocate
PrivateTmp=true

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 6.3 Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable nosniklocate.service
sudo systemctl start nosniklocate.service
```

### 6.4 Verify the service is running

```bash
# Check the service status
sudo systemctl status nosniklocate.service

# View recent logs
sudo journalctl -u nosniklocate.service -n 50 --no-pager

# Test the health endpoint through Nginx
curl -s https://your-domain.example.com/api/health | python3 -m json.tool
```

### 6.5 Useful service commands

```bash
# Restart after configuration changes
sudo systemctl restart nosniklocate.service

# Stop the service
sudo systemctl stop nosniklocate.service

# Follow logs in real time
sudo journalctl -u nosniklocate.service -f
```

---

## Step 7: Maintenance

### 7.1 Database backup script

Create a backup script at `/opt/nosniklocate/backup.sh`:

```bash
#!/usr/bin/env bash
# NosnikLocate database backup script
# Run via cron: 0 2 * * * /opt/nosniklocate/backup.sh

set -euo pipefail

BACKUP_DIR="/opt/nosniklocate/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/nosniklocate_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Dump and compress the database
pg_dump -U nosniklocate_user -h localhost nosniklocate | gzip > "$BACKUP_FILE"

# Remove backups older than the retention period
find "$BACKUP_DIR" -name "nosniklocate_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date --iso-8601=seconds)] Backup completed: $BACKUP_FILE"
```

Make it executable and schedule it:

```bash
chmod +x /opt/nosniklocate/backup.sh

# Add to crontab (runs daily at 2:00 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/nosniklocate/backup.sh >> /opt/nosniklocate/backups/backup.log 2>&1") | crontab -
```

### 7.2 Log rotation

Create a logrotate configuration at `/etc/logrotate.d/nosniklocate`:

```
/opt/nosniklocate/backups/backup.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nosniklocate nosniklocate
}
```

The application itself logs to the systemd journal, which has its own rotation configured
in `/etc/systemd/journald.conf`. To limit journal size:

```bash
sudo nano /etc/systemd/journald.conf
# Set: SystemMaxUse=500M
sudo systemctl restart systemd-journald
```

### 7.3 Monitoring

**Service health:**

```bash
# Service status
sudo systemctl status nosniklocate.service

# Live log stream
sudo journalctl -u nosniklocate.service -f

# Check if the process is running
pgrep -f "node src/server.js"
```

**Database monitoring:**

```bash
# Active connections
sudo -u postgres psql -d nosniklocate -c \
  "SELECT count(*) AS active_connections FROM pg_stat_activity WHERE datname = 'nosniklocate';"

# Table sizes
sudo -u postgres psql -d nosniklocate -c \
  "SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size
   FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;"

# Slow queries (requires pg_stat_statements extension)
sudo -u postgres psql -d nosniklocate -c \
  "SELECT query, calls, mean_exec_time, total_exec_time
   FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
```

**Nginx monitoring:**

```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log

# Connection stats
sudo nginx -T 2>/dev/null | grep -c "server"
```

### 7.4 Location data cleanup

Over time, the `user_locations` table will grow large. Schedule a cleanup job to delete
stale location entries:

```bash
# Delete location data older than 7 days
sudo -u postgres psql -d nosniklocate -c \
  "DELETE FROM user_locations WHERE timestamp < NOW() - INTERVAL '7 days';"
```

Automate this with a cron job:

```bash
(crontab -l 2>/dev/null; echo "0 3 * * * sudo -u postgres psql -d nosniklocate -c \"DELETE FROM user_locations WHERE timestamp < NOW() - INTERVAL '7 days';\" >> /opt/nosniklocate/backups/cleanup.log 2>&1") | crontab -
```

You can also run `VACUUM ANALYZE user_locations;` periodically to reclaim disk space and
update query planner statistics.

---

## Step 8: Privacy and Security

NosnikLocate is designed with privacy as a first-class concern. Here is a summary of the
security measures in place:

### Data sovereignty

- **All data is stored on your own server.** There are no third-party analytics, tracking
  pixels, or external data processors.
- **No data is sold or shared** with any third party under any circumstances.

### Authentication and authorization

- **Passwords are hashed with bcrypt** using a cost factor of 12, making brute-force
  attacks computationally expensive.
- **JWT authentication** with configurable expiry (default: 7 days). Tokens are signed
  with a server-side secret and verified on every authenticated request.
- The auth middleware (`middleware/auth.js`) extracts the `Bearer` token from the
  `Authorization` header and rejects requests with missing, expired, or invalid tokens.

### Transport security

- **HTTPS is enforced** via the Nginx reverse proxy. All HTTP traffic is redirected to
  HTTPS with a 301 response.
- **HSTS headers** are sent with a 2-year max-age to prevent downgrade attacks.
- TLS 1.2+ is required; weak ciphers are disabled.

### Rate limiting

Rate limiting is applied at **two layers**:

1. **Nginx level:** The `limit_req_zone` directive limits each IP to 10 requests per
   second with a burst of 20.
2. **Application level:** `express-rate-limit` enforces a sliding window of 100 requests
   per 15-minute window globally, and a stricter limit of 20 requests per 15 minutes on
   authentication endpoints (`/api/auth/*`).

### Input validation

- All endpoints use `express-validator` to validate and sanitize request bodies and
  parameters before processing.
- Usernames must be 3–50 alphanumeric characters or underscores.
- Emails are validated and normalized.
- Passwords must be at least 8 characters.
- Latitude/longitude values are validated to be within valid ranges.
- UUID parameters are validated before database queries.

### Security headers

The server uses `helmet` to set secure HTTP headers, and Nginx adds additional headers:

- `X-Frame-Options: DENY` — prevents clickjacking
- `X-Content-Type-Options: nosniff` — prevents MIME type sniffing
- `X-XSS-Protection: 1; mode=block` — enables browser XSS filter
- `Referrer-Policy: strict-origin-when-cross-origin` — limits referrer information
- `Content-Security-Policy: default-src 'none'` — restrictive CSP
- `Strict-Transport-Security` — enforces HTTPS

### Account and data deletion

- Users can **permanently delete their account** via `DELETE /api/user/account`.
- All associated data (locations, friendships, settings) is automatically removed through
  PostgreSQL `ON DELETE CASCADE` constraints.

### Location privacy

- Location data is **only shared with accepted friends** who have location sharing
  enabled (`share_location = TRUE` in `user_settings`).
- Stale location data (older than `LOCATION_STALE_MINUTES`, default 30 minutes) is
  automatically excluded from friend location queries.
- Users can disable location sharing at any time by updating their settings.

---

## API Reference

This section documents the most important API endpoints with request and response
examples. All authenticated endpoints require the `Authorization: Bearer <token>` header.

### Authentication

#### POST /api/auth/register

Create a new user account.

- **Auth required:** No
- **Rate limit:** 20 requests / 15 minutes

**Request body:**

```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "securepassword123",
  "display_name": "Alice"
}
```

**Success response (201):**

```json
{
  "message": "User registered successfully",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "username": "alice",
    "email": "alice@example.com",
    "display_name": "Alice"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error responses:**

| Status | Body                                                | Condition                             |
|--------|-----------------------------------------------------|---------------------------------------|
| 400    | `{ "errors": [...] }`                               | Validation failed                     |
| 409    | `{ "error": "Username or email already exists" }`   | Duplicate username or email           |

---

#### POST /api/auth/login

Authenticate an existing user.

- **Auth required:** No
- **Rate limit:** 20 requests / 15 minutes

**Request body:**

```json
{
  "username": "alice",
  "password": "securepassword123"
}
```

**Success response (200):**

```json
{
  "message": "Login successful",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "username": "alice",
    "email": "alice@example.com",
    "display_name": "Alice"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error responses:**

| Status | Body                                       | Condition                     |
|--------|--------------------------------------------|-------------------------------|
| 401    | `{ "error": "Invalid credentials" }`       | Wrong username or password    |
| 403    | `{ "error": "Account is deactivated" }`    | User account is inactive      |

---

#### POST /api/auth/logout

Log out the current user. The client should discard the JWT token.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "message": "Logged out successfully"
}
```

---

### User Management

#### GET /api/user/profile

Retrieve the authenticated user's profile.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "username": "alice",
    "email": "alice@example.com",
    "display_name": "Alice",
    "avatar_url": null,
    "created_at": "2024-01-15T10:00:00.000Z",
    "last_login": "2024-01-15T12:00:00.000Z"
  }
}
```

---

#### PUT /api/user/profile

Update the authenticated user's profile fields.

- **Auth required:** Yes

**Request body** (all fields optional):

```json
{
  "display_name": "Alice Wonderland",
  "email": "newalice@example.com",
  "avatar_url": "https://example.com/avatar.png"
}
```

**Success response (200):**

```json
{
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "username": "alice",
    "email": "newalice@example.com",
    "display_name": "Alice Wonderland",
    "avatar_url": "https://example.com/avatar.png",
    "updated_at": "2024-01-15T12:30:00.000Z"
  }
}
```

---

#### PUT /api/user/password

Change the authenticated user's password.

- **Auth required:** Yes

**Request body:**

```json
{
  "current_password": "securepassword123",
  "new_password": "evenmoresecure456"
}
```

**Success response (200):**

```json
{
  "message": "Password updated successfully"
}
```

---

#### DELETE /api/user/account

Permanently delete the authenticated user's account and all associated data.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "message": "Account deleted successfully"
}
```

---

### Location

#### POST /api/location/update

Submit the user's current location.

- **Auth required:** Yes

**Request body:**

```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 15.0
}
```

**Success response (200):**

```json
{
  "message": "Location updated",
  "location": {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "accuracy": 15.0,
    "timestamp": "2024-01-15T12:00:00.000Z"
  }
}
```

---

#### GET /api/location/friends

Get the most recent location of each accepted friend who has location sharing enabled.
Only locations newer than `LOCATION_STALE_MINUTES` are returned.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "friends": [
    {
      "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
      "username": "bob",
      "display_name": "Bob",
      "avatar_url": null,
      "latitude": 37.7849,
      "longitude": -122.4094,
      "accuracy": 10.0,
      "timestamp": "2024-01-15T11:58:00.000Z",
      "share_location": true
    }
  ]
}
```

---

### Friends

#### GET /api/friends

List all accepted friends.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "friends": [
    {
      "friendship_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
      "friend_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
      "username": "bob",
      "display_name": "Bob",
      "avatar_url": null,
      "created_at": "2024-01-10T08:00:00.000Z"
    }
  ]
}
```

---

#### POST /api/friends/request

Send a friend request to another user by username.

- **Auth required:** Yes

**Request body:**

```json
{
  "username": "bob"
}
```

**Success response (201):**

```json
{
  "message": "Friend request sent",
  "request": {
    "id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
    "status": "pending",
    "created_at": "2024-01-15T12:00:00.000Z"
  }
}
```

**Error responses:**

| Status | Body                                                   | Condition                              |
|--------|--------------------------------------------------------|----------------------------------------|
| 400    | `{ "error": "Cannot send a friend request to yourself" }` | Self-request                       |
| 404    | `{ "error": "User not found" }`                        | Target user does not exist             |
| 409    | `{ "error": "Already friends" }`                       | Friendship already accepted            |
| 409    | `{ "error": "Friend request already pending" }`        | Request already sent                   |
| 403    | `{ "error": "Unable to send friend request" }`         | User is blocked                        |

---

#### PUT /api/friends/request/:id/accept

Accept a pending friend request. Only the addressee can accept.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "message": "Friend request accepted",
  "friendship": {
    "id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
    "requester_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "status": "accepted",
    "updated_at": "2024-01-15T12:05:00.000Z"
  }
}
```

---

#### PUT /api/friends/request/:id/reject

Reject a pending friend request. Only the addressee can reject.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "message": "Friend request rejected",
  "friendship": {
    "id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
    "status": "rejected",
    "updated_at": "2024-01-15T12:05:00.000Z"
  }
}
```

---

#### DELETE /api/friends/:id

Remove an accepted friend. Either party can remove the friendship.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "message": "Friend removed"
}
```

---

#### GET /api/friends/requests/pending

List all incoming pending friend requests addressed to the authenticated user.

- **Auth required:** Yes

**Success response (200):**

```json
{
  "requests": [
    {
      "id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
      "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "username": "charlie",
      "display_name": "Charlie",
      "avatar_url": null,
      "created_at": "2024-01-15T11:00:00.000Z"
    }
  ]
}
```

---

### Health Check

#### GET /api/health

Returns the server status. Use this for uptime monitoring.

- **Auth required:** No

**Success response (200):**

```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:00:00.000Z"
}
```

---

## Troubleshooting

| Problem                              | Solution                                                                                  |
|--------------------------------------|-------------------------------------------------------------------------------------------|
| `ECONNREFUSED` on port 5432         | Ensure PostgreSQL is running: `sudo systemctl status postgresql`                          |
| `ECONNREFUSED` on port 6379         | Ensure Redis is running: `sudo systemctl status redis-server`                             |
| `error: password authentication failed` | Check `DB_PASSWORD` in `.env` matches the PostgreSQL user password                   |
| `JsonWebTokenError: invalid signature`  | Ensure `JWT_SECRET` in `.env` is the same value used when the token was issued        |
| `502 Bad Gateway` from Nginx         | Ensure the Node.js service is running: `sudo systemctl status nosniklocate`               |
| `ERR_SSL_PROTOCOL_ERROR`            | Ensure Certbot successfully obtained the certificate and Nginx was reloaded               |
| High memory usage                    | Check the connection pool size in `db/pool.js` (default: 20) and reduce if necessary      |
| Location queries are slow            | Verify the spatial GIST index exists: `\di idx_user_locations_gist` in psql               |

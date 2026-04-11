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

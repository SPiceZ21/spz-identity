-- spz-identity Database Schema

CREATE TABLE IF NOT EXISTS players (
  id               INT           AUTO_INCREMENT PRIMARY KEY,
  identifier       VARCHAR(64)   NOT NULL UNIQUE,   -- "license:xxxx"
  citizen_id       VARCHAR(10)   UNIQUE,            -- "SPZ-XXXXX"
  username         VARCHAR(64)   NULL UNIQUE,       -- globally unique name
  gender           VARCHAR(1)    NULL,              -- 'm' or 'f'
  first_time       TINYINT       DEFAULT 1,         -- 1 = needs character creation
  playtime         INT           DEFAULT 0,          -- total seconds on server
  xp               INT           DEFAULT 0,          -- raw XP (used by spz-progression)
  class_points     INT           DEFAULT 0,          -- points in current license class (season reset)
  alltime_points   INT           DEFAULT 0,          -- cumulative all-time, never resets
  sr               FLOAT         DEFAULT 2.0,        -- Safety Rating 0.00 – 5.00
  i_rating         INT           DEFAULT 1500,       -- Elo-style skill rating
  rank             VARCHAR(8)    DEFAULT 'C-5',      -- e.g. "B-3", "S-1"
  license_tier     TINYINT       DEFAULT 0,          -- 0=C  1=B  2=A  3=S
  top3_count       INT           DEFAULT 0,          -- top-3 finishes in current class
  crew_id          INT           NULL,
  credits          INT           DEFAULT 0,
  banned           TINYINT       DEFAULT 0,
  ban_reason       VARCHAR(255)  NULL,
  created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  last_seen        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_identifier  (identifier),
  INDEX idx_citizen_id  (citizen_id),
  INDEX idx_username    (username),
  INDEX idx_rank        (rank),
  INDEX idx_license     (license_tier),
  INDEX idx_crew        (crew_id)
);

CREATE TABLE IF NOT EXISTS crews (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(64)   NOT NULL UNIQUE,
  tag         VARCHAR(4)    NOT NULL,             -- e.g. "SPZ", "XRD"
  owner_id    INT           NOT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (owner_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS driver_licenses (
  id           INT         AUTO_INCREMENT PRIMARY KEY,
  player_id    INT         NOT NULL,
  tier         TINYINT     NOT NULL,              -- 0=C  1=B  2=A  3=S
  unlocked_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  method       VARCHAR(32) DEFAULT 'xp_threshold', -- 'xp_threshold' | 'admin_grant'

  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id)
);

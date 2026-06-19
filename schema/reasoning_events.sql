-- ECoT v0.1 canonical event store. SQLite, WAL, multi-writer safe.
-- Lives at: datasets/<repo>/reasoning/events.sqlite
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;

-- One row per atomic reasoning/action event, across ALL agents.
CREATE TABLE IF NOT EXISTS reasoning_events (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,

    -- TIME (the bridge to LeRobot)
    wall_ts         REAL    NOT NULL,         -- time.time() at emit
    mono_ts         REAL    NOT NULL,         -- time.monotonic() (ordering)
    episode_index   INTEGER,                  -- NULL = ambient (no active episode)
    frame_index     INTEGER,                  -- round((wall_ts - ep_start)*fps); NULL if ambient
    frame_span_lo   INTEGER,                  -- for spanning actions (motion)
    frame_span_hi   INTEGER,
    t_in_episode    REAL,                     -- seconds since episode start

    -- WHO
    agent_id        TEXT    NOT NULL,         -- main | thinker | telegram | voice
    session_id      TEXT    NOT NULL,         -- one agent run / turn
    turn_index      INTEGER NOT NULL DEFAULT 0,

    -- WHAT
    seq             INTEGER NOT NULL,         -- order WITHIN the turn (0,1,2,…)
    role            TEXT    NOT NULL,         -- user | assistant | system
    type            TEXT    NOT NULL,         -- user_input|reasoning|tool_use|tool_result|assistant_end
    tool_name       TEXT,                     -- for tool_use / tool_result
    tool_use_id     TEXT,                     -- correlates tool_use <-> tool_result

    -- CONTENT (structured; images dereferenced not embedded)
    text            TEXT,                     -- reasoning / prompt / result text
    tool_input      TEXT,                     -- JSON of toolUse.input
    image_refs      TEXT,                     -- JSON list: ["observation.images.front#frame=8", ...]
    meta            TEXT,                     -- JSON: anything extra (battery, gps snapshot, etc.)

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_re_episode  ON reasoning_events(episode_index, frame_index);
CREATE INDEX IF NOT EXISTS idx_re_session  ON reasoning_events(session_id, seq);
CREATE INDEX IF NOT EXISTS idx_re_agent    ON reasoning_events(agent_id, wall_ts);
CREATE INDEX IF NOT EXISTS idx_re_tooluse  ON reasoning_events(tool_use_id);

-- One row per agent session (turn) — holds the constant context.
CREATE TABLE IF NOT EXISTS reasoning_context (
    session_id      TEXT PRIMARY KEY,
    agent_id        TEXT NOT NULL,
    episode_index   INTEGER,
    model_id        TEXT,
    system_prompt   TEXT,                     -- full system prompt at turn start
    tool_specs      TEXT,                     -- JSON list of {name, description, input_schema}
    started_wall_ts REAL,
    started_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Episode time anchors (mirror of recorder state; exporter stays standalone).
CREATE TABLE IF NOT EXISTS episode_anchors (
    episode_index   INTEGER PRIMARY KEY,
    repo_id         TEXT,
    fps             REAL,
    start_wall_ts   REAL,
    stop_wall_ts    REAL,
    task            TEXT
);

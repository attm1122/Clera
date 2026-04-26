-- Clera Skin Session System — Supabase Schema
-- Non-clinical terminology throughout. No medical diagnosis fields.

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE face_zone AS ENUM (
  'forehead',
  'nose',
  'left_cheek',
  'right_cheek',
  'chin_jaw'
);

CREATE TYPE skin_metric AS ENUM (
  'breakouts',
  'redness',
  'dryness',
  'texture',
  'congestion',
  'irritation'
);

CREATE TYPE severity_level AS ENUM (
  'none',
  'low',
  'moderate',
  'high',
  'unknown'
);

CREATE TYPE trend_direction AS ENUM (
  'improving',
  'worsening',
  'stable',
  'unknown'
);

CREATE TYPE confidence_level AS ENUM (
  'low',
  'medium',
  'high'
);

CREATE TYPE routine_period AS ENUM (
  'am',
  'pm'
);

CREATE TYPE product_category AS ENUM (
  'cleanser',
  'moisturiser',
  'serum',
  'treatment',
  'spf',
  'mask',
  'other'
);

CREATE TYPE scan_status AS ENUM (
  'accepted',
  'rejected',
  'saved_low_confidence'
);

CREATE TYPE change_direction AS ENUM (
  'increasing',
  'decreasing',
  'stable'
);

CREATE TYPE change_magnitude AS ENUM (
  'slight',
  'moderate',
  'significant'
);

CREATE TYPE contributor_type AS ENUM (
  'routine',
  'product',
  'environment',
  'habit',
  'scan_quality',
  'unknown'
);

CREATE TYPE failure_code AS ENUM (
  'no_face_detected',
  'multiple_faces',
  'face_not_centred',
  'poor_lighting',
  'harsh_glare',
  'blurry_image',
  'face_too_close',
  'face_too_far',
  'extreme_head_angle',
  'scan_confidence_low',
  'missing_check_in',
  'no_routine',
  'no_previous_session',
  'inconsistent_history',
  'no_baseline',
  'uncertain_copilot'
);

-- =============================================================================
-- TRIGGER FUNCTION: updated_at
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PROFILES (extends auth.users)
-- =============================================================================

CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT,
  email           TEXT NOT NULL,
  skin_type       TEXT,
  sensitivity     TEXT,
  primary_concerns TEXT[] DEFAULT '{}',
  primary_goal    TEXT,
  age_range       TEXT,
  stress_level    TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (id = auth.uid());

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_profiles_email ON profiles(email);

-- =============================================================================
-- PRODUCTS
-- =============================================================================

CREATE TABLE products (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  category        product_category NOT NULL DEFAULT 'other',
  period          routine_period[] DEFAULT '{}',
  ingredient_tags TEXT[] DEFAULT '{}',
  is_active       BOOLEAN NOT NULL DEFAULT true,
  added_date      DATE DEFAULT CURRENT_DATE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own products"
  ON products FOR ALL USING (user_id = auth.uid());

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_products_user ON products(user_id);
CREATE INDEX idx_products_active ON products(user_id, is_active);

-- =============================================================================
-- ROUTINES
-- =============================================================================

CREATE TABLE routines (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT 'My Routine',
  period      routine_period NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE routines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own routines"
  ON routines FOR ALL USING (user_id = auth.uid());

CREATE TRIGGER routines_updated_at
  BEFORE UPDATE ON routines
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_routines_user ON routines(user_id);
CREATE INDEX idx_routines_user_period ON routines(user_id, period);

-- =============================================================================
-- ROUTINE STEPS
-- =============================================================================

CREATE TABLE routine_steps (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id  UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id) ON DELETE SET NULL,
  step_order  INT NOT NULL DEFAULT 0,
  category    product_category,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE routine_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own routine steps"
  ON routine_steps FOR ALL USING (user_id = auth.uid());

CREATE TRIGGER routine_steps_updated_at
  BEFORE UPDATE ON routine_steps
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_routine_steps_routine ON routine_steps(routine_id);
CREATE INDEX idx_routine_steps_user ON routine_steps(user_id);

-- =============================================================================
-- SKIN SESSIONS (unified pipeline output)
-- =============================================================================

CREATE TABLE skin_sessions (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_type          TEXT NOT NULL DEFAULT 'daily',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Confidence scores (typed columns, not JSONB)
  confidence_overall    NUMERIC(3,2) DEFAULT 0.50,
  confidence_scan       NUMERIC(3,2) DEFAULT 0.50,
  confidence_skin_map   NUMERIC(3,2) DEFAULT 0.50,
  confidence_changes    NUMERIC(3,2) DEFAULT 0.50,
  confidence_products   NUMERIC(3,2) DEFAULT 0.50,
  confidence_daily_plan NUMERIC(3,2) DEFAULT 0.50,

  -- Structured failures (well-defined shape, stored as JSONB for array flexibility)
  failures              JSONB DEFAULT '[]'::jsonb,

  -- User-facing notes
  user_note             TEXT
);

ALTER TABLE skin_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own skin sessions"
  ON skin_sessions FOR ALL USING (user_id = auth.uid());

CREATE TRIGGER skin_sessions_updated_at
  BEFORE UPDATE ON skin_sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_skin_sessions_user ON skin_sessions(user_id);
CREATE INDEX idx_skin_sessions_user_date ON skin_sessions(user_id, created_at DESC);

-- =============================================================================
-- SCANS
-- =============================================================================

CREATE TABLE scans (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id   UUID NOT NULL UNIQUE REFERENCES skin_sessions(id) ON DELETE CASCADE,
  status            scan_status NOT NULL DEFAULT 'accepted',
  captured_at       TIMESTAMPTZ DEFAULT now(),

  -- Photo metadata stored as JSONB (flexible: angle, url, dimensions)
  photos            JSONB DEFAULT '[]'::jsonb,

  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE scans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own scans"
  ON scans FOR ALL USING (user_id = auth.uid());

CREATE TRIGGER scans_updated_at
  BEFORE UPDATE ON scans
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_scans_user ON scans(user_id);
CREATE INDEX idx_scans_user_date ON scans(user_id, captured_at DESC);
CREATE INDEX idx_scans_skin_session ON scans(skin_session_id);

-- =============================================================================
-- SCAN QUALITY RESULTS
-- =============================================================================

CREATE TABLE scan_quality_results (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id     UUID NOT NULL UNIQUE REFERENCES skin_sessions(id) ON DELETE CASCADE,

  face_detected       BOOLEAN NOT NULL DEFAULT false,
  face_centered       BOOLEAN NOT NULL DEFAULT false,
  face_too_small      BOOLEAN NOT NULL DEFAULT false,
  face_too_large      BOOLEAN NOT NULL DEFAULT false,
  overexposed         BOOLEAN NOT NULL DEFAULT false,
  shadow_detected     BOOLEAN NOT NULL DEFAULT false,
  blur_score          NUMERIC(4,3) DEFAULT 0,
  brightness_score    NUMERIC(4,3) DEFAULT 0,
  contrast_score      NUMERIC(4,3) DEFAULT 0,
  sharpness_score     NUMERIC(4,3) DEFAULT 0,
  scan_readiness      TEXT DEFAULT 'not_ready',
  guidance_message    TEXT DEFAULT 'Position your face in the frame',
  confidence_score    NUMERIC(4,3) DEFAULT 0,
  is_valid            BOOLEAN NOT NULL DEFAULT true,
  validation_issues   TEXT[] DEFAULT '{}',
  validation_score    NUMERIC(3,2) DEFAULT 1.0,

  created_at          TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE scan_quality_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own scan quality"
  ON scan_quality_results FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_scan_quality_user ON scan_quality_results(user_id);
CREATE INDEX idx_scan_quality_session ON scan_quality_results(skin_session_id);

-- =============================================================================
-- CHECK INS
-- =============================================================================

CREATE TABLE check_ins (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id   UUID NOT NULL UNIQUE REFERENCES skin_sessions(id) ON DELETE CASCADE,

  followed_routine  BOOLEAN NOT NULL DEFAULT false,
  new_products      BOOLEAN NOT NULL DEFAULT false,
  had_irritation    BOOLEAN NOT NULL DEFAULT false,
  had_dryness       BOOLEAN NOT NULL DEFAULT false,
  had_breakouts     BOOLEAN NOT NULL DEFAULT false,
  notes             TEXT,

  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own check-ins"
  ON check_ins FOR ALL USING (user_id = auth.uid());

CREATE INDEX idx_check_ins_user ON check_ins(user_id);
CREATE INDEX idx_check_ins_session ON check_ins(skin_session_id);

-- =============================================================================
-- SKIN MAPS
-- =============================================================================

CREATE TABLE skin_maps (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id   UUID NOT NULL UNIQUE REFERENCES skin_sessions(id) ON DELETE CASCADE,
  mapped_at         TIMESTAMPTZ DEFAULT now(),
  confidence_level  confidence_level NOT NULL DEFAULT 'low',
  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE skin_maps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own skin maps"
  ON skin_maps FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_skin_maps_user ON skin_maps(user_id);
CREATE INDEX idx_skin_maps_session ON skin_maps(skin_session_id);

-- =============================================================================
-- SKIN ZONE STATUSES
-- =============================================================================

CREATE TABLE skin_zone_statuses (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_map_id       UUID NOT NULL REFERENCES skin_maps(id) ON DELETE CASCADE,
  face_zone         face_zone NOT NULL,
  metric            skin_metric NOT NULL,
  severity          severity_level NOT NULL DEFAULT 'unknown',
  trend             trend_direction NOT NULL DEFAULT 'unknown',

  UNIQUE (skin_map_id, face_zone, metric)
);

ALTER TABLE skin_zone_statuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own zone statuses"
  ON skin_zone_statuses FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_zone_statuses_map ON skin_zone_statuses(skin_map_id);
CREATE INDEX idx_zone_statuses_zone ON skin_zone_statuses(face_zone);
CREATE INDEX idx_zone_statuses_user_zone ON skin_zone_statuses(user_id, face_zone);

-- =============================================================================
-- ZONE CHANGES (change detection output)
-- =============================================================================

CREATE TABLE zone_changes (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id   UUID NOT NULL REFERENCES skin_sessions(id) ON DELETE CASCADE,
  face_zone         face_zone NOT NULL,
  metric            skin_metric NOT NULL,
  direction         change_direction NOT NULL,
  magnitude         change_magnitude NOT NULL,
  confidence        NUMERIC(3,2) NOT NULL DEFAULT 0.50,
  explanation       TEXT NOT NULL DEFAULT '',
  compared_map_ids  UUID[] DEFAULT '{}',
  detection_mode    TEXT NOT NULL DEFAULT 'latest_pair',
  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE zone_changes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own zone changes"
  ON zone_changes FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_zone_changes_session ON zone_changes(skin_session_id);
CREATE INDEX idx_zone_changes_user_zone ON zone_changes(user_id, face_zone);
CREATE INDEX idx_zone_changes_user_metric ON zone_changes(user_id, metric);

-- =============================================================================
-- DAILY PLANS
-- =============================================================================

CREATE TABLE daily_plans (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  skin_session_id   UUID UNIQUE REFERENCES skin_sessions(id) ON DELETE CASCADE,

  period            routine_period NOT NULL,
  focus             TEXT NOT NULL DEFAULT 'Maintain and protect',
  confidence_level  confidence_level NOT NULL DEFAULT 'low',

  -- Array fields with well-defined shapes
  avoid_items       TEXT[] DEFAULT '{}',
  reasoning         TEXT[] DEFAULT '{}',

  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE daily_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own daily plans"
  ON daily_plans FOR SELECT USING (user_id = auth.uid());

CREATE TRIGGER daily_plans_updated_at
  BEFORE UPDATE ON daily_plans
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_daily_plans_user ON daily_plans(user_id);
CREATE INDEX idx_daily_plans_session ON daily_plans(skin_session_id);

-- =============================================================================
-- DAILY PLAN STEPS
-- =============================================================================

CREATE TABLE daily_plan_steps (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_plan_id   UUID NOT NULL REFERENCES daily_plans(id) ON DELETE CASCADE,
  product_id      UUID REFERENCES products(id) ON DELETE SET NULL,

  step_order      INT NOT NULL DEFAULT 0,
  category        product_category,
  product_name    TEXT,
  instruction     TEXT,
  is_optional     BOOLEAN NOT NULL DEFAULT false,

  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE daily_plan_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own plan steps"
  ON daily_plan_steps FOR SELECT USING (user_id = auth.uid());

CREATE TRIGGER daily_plan_steps_updated_at
  BEFORE UPDATE ON daily_plan_steps
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_daily_plan_steps_plan ON daily_plan_steps(daily_plan_id);
CREATE INDEX idx_daily_plan_steps_user ON daily_plan_steps(user_id);

-- =============================================================================
-- WEEKLY INSIGHTS
-- =============================================================================

CREATE TABLE weekly_insights (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  week_ending           DATE NOT NULL DEFAULT CURRENT_DATE,
  summary_title         TEXT NOT NULL DEFAULT '',
  summary_text          TEXT NOT NULL DEFAULT '',
  recommended_next_step TEXT NOT NULL DEFAULT '',
  confidence_level      confidence_level NOT NULL DEFAULT 'low',
  safety_disclaimer     TEXT NOT NULL DEFAULT 'Clera tracks visible signs and reported changes only. This is not a medical diagnosis. If you have concerns about your skin, consult a dermatologist.',

  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE weekly_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own weekly insights"
  ON weekly_insights FOR SELECT USING (user_id = auth.uid());

CREATE TRIGGER weekly_insights_updated_at
  BEFORE UPDATE ON weekly_insights
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_weekly_insights_user ON weekly_insights(user_id);
CREATE INDEX idx_weekly_insights_user_week ON weekly_insights(user_id, week_ending DESC);

-- =============================================================================
-- INSIGHT CONTRIBUTORS
-- =============================================================================

CREATE TABLE insight_contributors (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weekly_insight_id UUID NOT NULL REFERENCES weekly_insights(id) ON DELETE CASCADE,

  contributor_type  contributor_type NOT NULL DEFAULT 'unknown',
  description       TEXT NOT NULL DEFAULT '',
  confidence_level  confidence_level NOT NULL DEFAULT 'low',

  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE insight_contributors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own contributors"
  ON insight_contributors FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_insight_contributors_insight ON insight_contributors(weekly_insight_id);
CREATE INDEX idx_insight_contributors_user ON insight_contributors(user_id);

-- =============================================================================
-- INSIGHT ZONE HIGHLIGHTS
-- =============================================================================

CREATE TABLE insight_zone_highlights (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weekly_insight_id UUID NOT NULL REFERENCES weekly_insights(id) ON DELETE CASCADE,

  face_zone         face_zone NOT NULL,
  trend             trend_direction NOT NULL,
  primary_metric    skin_metric NOT NULL,
  description       TEXT NOT NULL DEFAULT '',

  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE insight_zone_highlights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own zone highlights"
  ON insight_zone_highlights FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_zone_highlights_insight ON insight_zone_highlights(weekly_insight_id);
CREATE INDEX idx_zone_highlights_user_zone ON insight_zone_highlights(user_id, face_zone);

-- =============================================================================
-- ROUTINE CHANGE LOG
-- =============================================================================

CREATE TABLE routine_change_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  change_type TEXT NOT NULL DEFAULT 'added',
  notes       TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE routine_change_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own change logs"
  ON routine_change_logs FOR SELECT USING (user_id = auth.uid());

CREATE INDEX idx_routine_change_logs_user ON routine_change_logs(user_id);
CREATE INDEX idx_routine_change_logs_product ON routine_change_logs(product_id);

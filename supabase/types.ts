/**
 * Clera Skin Session System — TypeScript types for Supabase schema.
 * Non-clinical terminology throughout. No medical diagnosis fields.
 */

// =============================================================================
// ENUMS
// =============================================================================

export type FaceZone =
  | 'forehead'
  | 'nose'
  | 'left_cheek'
  | 'right_cheek'
  | 'chin_jaw';

export type SkinMetric =
  | 'breakouts'
  | 'redness'
  | 'dryness'
  | 'texture'
  | 'congestion'
  | 'irritation';

export type SeverityLevel =
  | 'none'
  | 'low'
  | 'moderate'
  | 'high'
  | 'unknown';

export type TrendDirection =
  | 'improving'
  | 'worsening'
  | 'stable'
  | 'unknown';

export type ConfidenceLevel =
  | 'low'
  | 'medium'
  | 'high';

export type RoutinePeriod =
  | 'am'
  | 'pm';

export type ProductCategory =
  | 'cleanser'
  | 'moisturiser'
  | 'serum'
  | 'treatment'
  | 'spf'
  | 'mask'
  | 'other';

export type ScanStatus =
  | 'accepted'
  | 'rejected'
  | 'saved_low_confidence';

export type ChangeDirection =
  | 'increasing'
  | 'decreasing'
  | 'stable';

export type ChangeMagnitude =
  | 'slight'
  | 'moderate'
  | 'significant';

export type ContributorType =
  | 'routine'
  | 'product'
  | 'environment'
  | 'habit'
  | 'scan_quality'
  | 'unknown';

export type FailureCode =
  | 'no_face_detected'
  | 'multiple_faces'
  | 'face_not_centred'
  | 'poor_lighting'
  | 'harsh_glare'
  | 'blurry_image'
  | 'face_too_close'
  | 'face_too_far'
  | 'extreme_head_angle'
  | 'scan_confidence_low'
  | 'missing_check_in'
  | 'no_routine'
  | 'no_previous_session'
  | 'inconsistent_history'
  | 'no_baseline'
  | 'uncertain_copilot';

// =============================================================================
// JSONB STRUCTURES
// =============================================================================

export interface SessionFailure {
  id: string;
  failure_code: FailureCode;
  user_message: string;
  recommended_action: string;
  can_continue: boolean;
  confidence_impact: number;
  is_resolved: boolean;
}

export interface ScanPhoto {
  id: string;
  angle: 'front' | 'left' | 'right';
  url?: string;
  captured_at: string;
}

export interface HeadPose {
  pitch: number;
  yaw: number;
  roll: number;
}

// =============================================================================
// CORE TABLES
// =============================================================================

export interface Profile {
  id: string;
  name: string | null;
  email: string;
  skin_type: string | null;
  sensitivity: string | null;
  primary_concerns: string[];
  primary_goal: string | null;
  age_range: string | null;
  stress_level: string | null;
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: string;
  user_id: string;
  name: string;
  category: ProductCategory;
  period: RoutinePeriod[];
  ingredient_tags: string[];
  is_active: boolean;
  added_date: string;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface Routine {
  id: string;
  user_id: string;
  name: string;
  period: RoutinePeriod;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface RoutineStep {
  id: string;
  user_id: string;
  routine_id: string;
  product_id: string | null;
  step_order: number;
  category: ProductCategory | null;
  created_at: string;
  updated_at: string;
}

export interface RoutineChangeLog {
  id: string;
  user_id: string;
  product_id: string;
  change_type: 'added' | 'removed' | 'switched';
  notes: string | null;
  created_at: string;
}

// =============================================================================
// SKIN SESSION SYSTEM
// =============================================================================

export interface SkinSession {
  id: string;
  user_id: string;
  session_type: 'baseline' | 'daily' | 'weekly' | 'check_in' | 'experiment_start' | 'experiment_end';
  created_at: string;
  updated_at: string;

  confidence_overall: number;
  confidence_scan: number;
  confidence_skin_map: number;
  confidence_changes: number;
  confidence_products: number;
  confidence_daily_plan: number;

  failures: SessionFailure[];
  user_note: string | null;
}

export interface Scan {
  id: string;
  user_id: string;
  skin_session_id: string;
  status: ScanStatus;
  captured_at: string;
  photos: ScanPhoto[];
  created_at: string;
  updated_at: string;
}

export interface ScanQualityResult {
  id: string;
  user_id: string;
  skin_session_id: string;

  face_detected: boolean;
  face_centered: boolean;
  face_too_small: boolean;
  face_too_large: boolean;
  overexposed: boolean;
  shadow_detected: boolean;
  blur_score: number;
  brightness_score: number;
  contrast_score: number;
  sharpness_score: number;
  scan_readiness: string;
  guidance_message: string;
  confidence_score: number;

  is_valid: boolean;
  validation_issues: string[];
  validation_score: number;

  created_at: string;
}

export interface CheckIn {
  id: string;
  user_id: string;
  skin_session_id: string;

  followed_routine: boolean;
  new_products: boolean;
  had_irritation: boolean;
  had_dryness: boolean;
  had_breakouts: boolean;
  notes: string | null;

  created_at: string;
}

export interface SkinMap {
  id: string;
  user_id: string;
  skin_session_id: string;
  mapped_at: string;
  confidence_level: ConfidenceLevel;
  created_at: string;
}

export interface SkinZoneStatus {
  id: string;
  user_id: string;
  skin_map_id: string;
  face_zone: FaceZone;
  metric: SkinMetric;
  severity: SeverityLevel;
  trend: TrendDirection;
}

export interface ZoneChange {
  id: string;
  user_id: string;
  skin_session_id: string;
  face_zone: FaceZone;
  metric: SkinMetric;
  direction: ChangeDirection;
  magnitude: ChangeMagnitude;
  confidence: number;
  explanation: string;
  compared_map_ids: string[];
  detection_mode: 'latest_pair' | 'rolling_3_scan' | 'seven_day';
  created_at: string;
}

// =============================================================================
// DAILY COPILOT
// =============================================================================

export interface DailyPlan {
  id: string;
  user_id: string;
  skin_session_id: string | null;

  period: RoutinePeriod;
  focus: string;
  confidence_level: ConfidenceLevel;

  avoid_items: string[];
  reasoning: string[];

  created_at: string;
  updated_at: string;
}

export interface DailyPlanStep {
  id: string;
  user_id: string;
  daily_plan_id: string;
  product_id: string | null;

  step_order: number;
  category: ProductCategory | null;
  product_name: string | null;
  instruction: string | null;
  is_optional: boolean;

  created_at: string;
  updated_at: string;
}

// =============================================================================
// WEEKLY INSIGHTS
// =============================================================================

export interface WeeklyInsight {
  id: string;
  user_id: string;

  week_ending: string;
  summary_title: string;
  summary_text: string;
  recommended_next_step: string;
  confidence_level: ConfidenceLevel;
  safety_disclaimer: string;

  created_at: string;
  updated_at: string;
}

export interface InsightContributor {
  id: string;
  user_id: string;
  weekly_insight_id: string;

  contributor_type: ContributorType;
  description: string;
  confidence_level: ConfidenceLevel;

  created_at: string;
}

export interface InsightZoneHighlight {
  id: string;
  user_id: string;
  weekly_insight_id: string;

  face_zone: FaceZone;
  trend: TrendDirection;
  primary_metric: SkinMetric;
  description: string;

  created_at: string;
}

// =============================================================================
// SUPABASE DATABASE TYPE (for generated clients)
// =============================================================================

export interface CleraDatabase {
  profiles: {
    Row: Profile;
    Insert: Omit<Profile, 'created_at' | 'updated_at'> & Partial<Pick<Profile, 'created_at' | 'updated_at'>>;
    Update: Partial<Profile>;
  };
  products: {
    Row: Product;
    Insert: Omit<Product, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<Product, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<Product>;
  };
  routines: {
    Row: Routine;
    Insert: Omit<Routine, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<Routine, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<Routine>;
  };
  routine_steps: {
    Row: RoutineStep;
    Insert: Omit<RoutineStep, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<RoutineStep, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<RoutineStep>;
  };
  routine_change_logs: {
    Row: RoutineChangeLog;
    Insert: Omit<RoutineChangeLog, 'id' | 'created_at'> & Partial<Pick<RoutineChangeLog, 'id' | 'created_at'>>;
    Update: Partial<RoutineChangeLog>;
  };
  skin_sessions: {
    Row: SkinSession;
    Insert: Omit<SkinSession, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<SkinSession, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<SkinSession>;
  };
  scans: {
    Row: Scan;
    Insert: Omit<Scan, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<Scan, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<Scan>;
  };
  scan_quality_results: {
    Row: ScanQualityResult;
    Insert: Omit<ScanQualityResult, 'id' | 'created_at'> & Partial<Pick<ScanQualityResult, 'id' | 'created_at'>>;
    Update: Partial<ScanQualityResult>;
  };
  check_ins: {
    Row: CheckIn;
    Insert: Omit<CheckIn, 'id' | 'created_at'> & Partial<Pick<CheckIn, 'id' | 'created_at'>>;
    Update: Partial<CheckIn>;
  };
  skin_maps: {
    Row: SkinMap;
    Insert: Omit<SkinMap, 'id' | 'created_at'> & Partial<Pick<SkinMap, 'id' | 'created_at'>>;
    Update: Partial<SkinMap>;
  };
  skin_zone_statuses: {
    Row: SkinZoneStatus;
    Insert: Omit<SkinZoneStatus, 'id'> & Partial<Pick<SkinZoneStatus, 'id'>>;
    Update: Partial<SkinZoneStatus>;
  };
  zone_changes: {
    Row: ZoneChange;
    Insert: Omit<ZoneChange, 'id' | 'created_at'> & Partial<Pick<ZoneChange, 'id' | 'created_at'>>;
    Update: Partial<ZoneChange>;
  };
  daily_plans: {
    Row: DailyPlan;
    Insert: Omit<DailyPlan, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<DailyPlan, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<DailyPlan>;
  };
  daily_plan_steps: {
    Row: DailyPlanStep;
    Insert: Omit<DailyPlanStep, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<DailyPlanStep, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<DailyPlanStep>;
  };
  weekly_insights: {
    Row: WeeklyInsight;
    Insert: Omit<WeeklyInsight, 'id' | 'created_at' | 'updated_at'> & Partial<Pick<WeeklyInsight, 'id' | 'created_at' | 'updated_at'>>;
    Update: Partial<WeeklyInsight>;
  };
  insight_contributors: {
    Row: InsightContributor;
    Insert: Omit<InsightContributor, 'id' | 'created_at'> & Partial<Pick<InsightContributor, 'id' | 'created_at'>>;
    Update: Partial<InsightContributor>;
  };
  insight_zone_highlights: {
    Row: InsightZoneHighlight;
    Insert: Omit<InsightZoneHighlight, 'id' | 'created_at'> & Partial<Pick<InsightZoneHighlight, 'id' | 'created_at'>>;
    Update: Partial<InsightZoneHighlight>;
  };
}


// =============================================================================
// PIPELINE RESULT TYPES
// =============================================================================

export type PipelineScanStatus =
  | 'accepted'
  | 'saved_low_confidence'
  | 'rejected';

export interface SkinSessionResult {
  id: string;
  session_id: string;
  created_at: string;
  scan_status: PipelineScanStatus;
  is_baseline: boolean;
  failure_state: FailureState | null;
  skin_map: SkinMap;
  zone_changes: ZoneChange[];
  daily_plan: DailyPlan;
  confidence_summary: ConfidenceSummary;
  user_messages: string[];
  analytics_events: AnalyticsEvent[];
  check_in: CheckIn | null;
  weekly_insight: WeeklyInsight | null;
}

export interface FailureState {
  code: FailureCode;
  user_message: string;
  recommended_action: string;
  can_continue: boolean;
  confidence_impact: number;
}

export interface ConfidenceSummary {
  overall: number;
  scan_quality: number;
  skin_map: number;
  change_detection: number;
  product_intelligence: number;
  daily_plan: number;
  adjusted_for_failures: boolean;
}

export interface PipelineContext {
  scan_session: Scan;
  check_in: CheckIn | null;
  current_products: Product[];
  routine_logs: RoutineLogEntry[];
  routine_changes: RoutineChangeLog[];
  all_sessions: Scan[];
  skin_map_history: SkinMap[];
  experiments: Experiment[];
  scan_failures: SessionFailure[];
}

export interface PipelineStepResult {
  step_name: string;
  succeeded: boolean;
  skipped: boolean;
  reason: string | null;
}

export type AnalyticsEvent =
  | 'scan_started'
  | 'scan_rejected'
  | 'scan_saved_low_confidence'
  | 'baseline_created'
  | 'skin_session_completed'
  | 'daily_plan_generated'
  | 'fallback_plan_generated'
  | 'pipeline_error';

// =============================================================================
// ADDITIONAL SUPPORTING TYPES
// =============================================================================

export interface RoutineLogEntry {
  id: string;
  user_id: string;
  date: string;
  followed_routine: boolean;
  product_ids: string[];
  notes: string | null;
}

export interface Experiment {
  id: string;
  user_id: string;
  name: string;
  zone: FaceZone;
  hypothesis: string;
  duration_days: number;
  is_active: boolean;
  start_date: string;
  end_date: string | null;
  related_product_ids: string[];
  result: ExperimentResult | null;
}

export interface ExperimentResult {
  outcome: 'improvement' | 'no_change' | 'worsened';
  notes: string | null;
  final_skin_map_id: string | null;
}

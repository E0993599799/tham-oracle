-- Omega Self-Evolution Phase 2 Runtime Ledger
-- Status: design draft only
-- Target: Supabase/Postgres

create extension if not exists vector;
create extension if not exists pgcrypto;

create table if not exists task_traces (
  trace_id text primary key,
  task_id text not null,
  cycle_type text not null check (cycle_type in ('12h','daily','weekly','ad_hoc')),
  automation_name text not null,
  agent_name text,
  lane text not null,
  provider_name text,
  model_name text,
  contract_ref text not null,
  input_summary text,
  output_summary text,
  status text not null check (status in ('queued','running','passed','failed','blocked','cancelled')),
  started_at timestamptz not null,
  ended_at timestamptz,
  latency_ms integer check (latency_ms >= 0),
  token_usage integer check (token_usage >= 0),
  cost_usd numeric(12,6) check (cost_usd >= 0),
  dashboard_card text,
  obsidian_writeback_path text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists proof_artifacts (
  proof_id text primary key,
  task_id text not null,
  trace_id text references task_traces(trace_id) on delete cascade,
  artifact_type text not null check (artifact_type in ('json','md','png','log','csv','html','jsonl','screenshot','other')),
  status text not null check (status in ('valid','weak','missing','rejected','superseded')),
  created_at timestamptz not null,
  uri text not null,
  sha256 text not null,
  summary text,
  verifier text,
  evidence jsonb not null default '[]'::jsonb,
  related_paths jsonb not null default '[]'::jsonb,
  source_system text,
  created_row_at timestamptz not null default now()
);

create table if not exists failure_events (
  failure_id text primary key,
  timestamp timestamptz not null,
  class text not null check (class in ('PROMPT_FAIL','TOOL_FAIL','MEMORY_FAIL','SOT_FAIL','EXEC_FAIL','PROOF_FAIL','COST_FAIL','LATENCY_FAIL','UX_FAIL','SECURITY_FAIL','LOOP_FAIL','ROUTER_FAIL','OBSIDIAN_WRITEBACK_FAIL','DASHBOARD_FAIL')),
  severity text not null check (severity in ('SEV-1','SEV-2','SEV-3','SEV-4','SEV-5')),
  component text not null,
  summary text not null,
  detection_signal text not null,
  containment_action text not null,
  prevention_rule text,
  required_proof text not null,
  related_task_id text,
  related_trace_id text references task_traces(trace_id) on delete set null,
  proof_artifact_id text references proof_artifacts(proof_id) on delete set null,
  root_cause_candidate text,
  status text not null check (status in ('open','contained','resolved','wont_fix')),
  created_at timestamptz not null default now()
);

create table if not exists agent_scorecards (
  scorecard_id uuid primary key default gen_random_uuid(),
  review_date date not null,
  cycle_scope text not null check (cycle_scope in ('12h','daily','weekly')),
  agent_name text not null,
  lane text,
  provider_name text,
  model_name text,
  task_count integer not null default 0,
  pass_count integer not null default 0,
  fail_count integer not null default 0,
  blocked_count integer not null default 0,
  weak_proof_count integer not null default 0,
  avg_latency_ms integer,
  total_tokens bigint,
  total_cost_usd numeric(12,6),
  recommendation text check (recommendation in ('keep','narrow','quarantine','retire','investigate')),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists automation_runs (
  run_id text primary key,
  automation_name text not null,
  trigger_type text not null check (trigger_type in ('cron','manual','event','watchdog')),
  schedule_ref text,
  status text not null check (status in ('queued','running','passed','failed','blocked','cancelled','timed_out')),
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_ms integer check (duration_ms >= 0),
  retry_count integer not null default 0,
  kill_switch_state boolean not null default false,
  disable_reason text,
  trace_id text references task_traces(trace_id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists memory_candidates (
  candidate_id uuid primary key default gen_random_uuid(),
  candidate_type text not null check (candidate_type in ('semantic_memory','procedural_memory','policy_memory')),
  title text not null,
  summary text not null,
  source_trace_id text references task_traces(trace_id) on delete set null,
  source_failure_id text references failure_events(failure_id) on delete set null,
  evidence jsonb not null default '[]'::jsonb,
  review_state text not null check (review_state in ('proposed','in_review','approved','rejected','superseded','applied')),
  approved_writeback_path text,
  reviewer text,
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists skill_candidates (
  candidate_id uuid primary key default gen_random_uuid(),
  skill_slug text not null,
  title text not null,
  summary text not null,
  source_trace_ids jsonb not null default '[]'::jsonb,
  evidence jsonb not null default '[]'::jsonb,
  rollback_plan text,
  test_plan text,
  review_state text not null check (review_state in ('proposed','in_review','approved','rejected','superseded','applied')),
  reviewer text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists prompt_patch_candidates (
  candidate_id uuid primary key default gen_random_uuid(),
  target_prompt text not null,
  title text not null,
  rationale text not null,
  proposed_patch text not null,
  source_failure_ids jsonb not null default '[]'::jsonb,
  evidence jsonb not null default '[]'::jsonb,
  rollback_plan text,
  review_state text not null check (review_state in ('proposed','in_review','approved','rejected','superseded','applied')),
  reviewer text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists memory_embeddings (
  embedding_id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('memory_candidate','skill_candidate','prompt_patch_candidate','approved_memory','approved_skill')),
  source_id text not null,
  content text not null,
  embedding vector(1536),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_task_traces_started_at on task_traces(started_at desc);
create index if not exists idx_task_traces_status on task_traces(status);
create index if not exists idx_task_traces_automation_name on task_traces(automation_name);
create index if not exists idx_task_traces_lane on task_traces(lane);
create index if not exists idx_task_traces_agent_name on task_traces(agent_name);

create index if not exists idx_proof_artifacts_trace_id on proof_artifacts(trace_id);
create index if not exists idx_proof_artifacts_status on proof_artifacts(status);
create index if not exists idx_proof_artifacts_created_at on proof_artifacts(created_at desc);

create index if not exists idx_failure_events_timestamp on failure_events(timestamp desc);
create index if not exists idx_failure_events_class on failure_events(class);
create index if not exists idx_failure_events_severity on failure_events(severity);
create index if not exists idx_failure_events_component on failure_events(component);
create index if not exists idx_failure_events_status on failure_events(status);

create index if not exists idx_agent_scorecards_review_date on agent_scorecards(review_date desc);
create index if not exists idx_agent_scorecards_agent_name on agent_scorecards(agent_name);
create index if not exists idx_agent_scorecards_lane on agent_scorecards(lane);

create index if not exists idx_automation_runs_name on automation_runs(automation_name);
create index if not exists idx_automation_runs_started_at on automation_runs(started_at desc);
create index if not exists idx_automation_runs_status on automation_runs(status);

create index if not exists idx_memory_candidates_review_state on memory_candidates(review_state);
create index if not exists idx_memory_candidates_type on memory_candidates(candidate_type);
create index if not exists idx_memory_candidates_created_at on memory_candidates(created_at desc);

create index if not exists idx_skill_candidates_review_state on skill_candidates(review_state);
create index if not exists idx_skill_candidates_created_at on skill_candidates(created_at desc);

create index if not exists idx_prompt_patch_candidates_review_state on prompt_patch_candidates(review_state);
create index if not exists idx_prompt_patch_candidates_created_at on prompt_patch_candidates(created_at desc);

create index if not exists idx_memory_embeddings_source on memory_embeddings(source_type, source_id);
create index if not exists idx_memory_embeddings_vector on memory_embeddings using ivfflat (embedding vector_cosine_ops);

create or replace view vw_recent_failures as
select failure_id, timestamp, class, severity, component, summary, status, related_trace_id
from failure_events
order by timestamp desc;

create or replace view vw_weak_proofs as
select proof_id, trace_id, task_id, artifact_type, status, created_at, uri, summary
from proof_artifacts
where status in ('weak','missing','rejected')
order by created_at desc;

create or replace view vw_automation_health as
select automation_name,
       count(*) filter (where status = 'passed') as passed_runs,
       count(*) filter (where status in ('failed','blocked','timed_out')) as bad_runs,
       max(started_at) as last_started_at,
       max(ended_at) as last_ended_at
from automation_runs
group by automation_name;

-- devices
create table if not exists public.devices (
  id         uuid primary key default gen_random_uuid(),
  entity_id  text,
  name       text,
  created_at timestamptz not null default now(),
  location   text
);
create index if not exists idx_devices_entity_id on public.devices (entity_id);

-- sensor_readings
create table if not exists public.sensor_readings (
  id         bigint generated always as identity primary key,
  timestamp  timestamptz not null,
  device_id  uuid not null references public.devices (id),
  metric     text not null,
  value      double precision not null,
  attributes jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_sensor_readings_device_id on public.sensor_readings (device_id);
create index if not exists idx_sensor_readings_metric on public.sensor_readings (metric);
create index if not exists idx_sensor_readings_timestamp on public.sensor_readings (timestamp desc);
create index if not exists idx_sensor_readings_device_metric_ts on public.sensor_readings (device_id, metric, timestamp desc);

-- temperature_sensors
create table if not exists public.temperature_sensors (
  id                      uuid primary key default gen_random_uuid(),
  sensor_code             text not null,
  display_name            text not null,
  location_name           text not null,
  sensor_type             text not null,
  color_code              text not null,
  active                  boolean not null default true,
  email_reporting_enabled boolean not null default false,
  threshold_min_c         numeric,
  threshold_max_c         numeric,
  timezone                text not null default 'Asia/Bangkok',
  metadata                jsonb not null default '{}',
  created_by              uuid,
  updated_by              uuid,
  deleted_at              timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- temperature_report_dispatches
create extension if not exists pgcrypto;

create table if not exists public.temperature_report_dispatches (
  id              uuid primary key default gen_random_uuid(),
  dataset_id      text not null,
  recipient_email text not null,
  report_title    text not null,
  branch_label    text not null,
  month_label     text not null,
  download_url    text not null,
  provider        text not null default 'supabase_edge_queue',
  status          text not null default 'queued',
  error_message   text,
  metadata        jsonb not null default '{}'::jsonb,
  requested_at    timestamptz not null default now(),
  sent_at         timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint chk_temperature_report_dispatches_status
    check (status in ('queued', 'sent', 'failed'))
);

create index if not exists idx_temperature_report_dispatches_status
  on public.temperature_report_dispatches (status, requested_at desc);

create index if not exists idx_temperature_report_dispatches_email
  on public.temperature_report_dispatches (recipient_email, requested_at desc);

create or replace function public.set_temperature_report_dispatches_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_temperature_report_dispatches_updated_at on public.temperature_report_dispatches;
create trigger trg_temperature_report_dispatches_updated_at
before update on public.temperature_report_dispatches
for each row execute function public.set_temperature_report_dispatches_updated_at();

comment on table public.temperature_report_dispatches is
'Queue of report-delivery requests created by Mission Control temperature-monitoring pages.';

-- temperature_email_recipients
create table if not exists public.temperature_email_recipients (
  id              uuid primary key default gen_random_uuid(),
  recipient_email text not null,
  recipient_name  text,
  scope_type      text not null,
  location_name   text,
  sensor_id       uuid references public.temperature_sensors (id),
  report_kind     text not null,
  enabled         boolean not null default true,
  metadata        jsonb not null default '{}',
  created_by      uuid,
  updated_by      uuid,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- temperature_email_delivery_log
create table if not exists public.temperature_email_delivery_log (
  id              uuid primary key default gen_random_uuid(),
  report_kind     text not null,
  recipient_email text not null,
  report_date     date not null,
  slot_label      text not null,
  status          text not null,
  error_message   text,
  payload         jsonb not null default '{}',
  requested_at    timestamptz not null default now(),
  sent_at         timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

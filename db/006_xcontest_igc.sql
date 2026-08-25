CREATE TABLE IF NOT EXISTS pilot_external_profiles (
  pilot_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'xcontest' CHECK (provider = 'xcontest'),
  external_username text,
  external_profile_url text,
  fai_id_snapshot text,
  consent_public boolean NOT NULL DEFAULT false,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS external_flights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pilot_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'xctrack_igc' CHECK (provider = 'xctrack_igc'),
  flown_at timestamptz NOT NULL,
  duration_seconds integer NOT NULL CHECK (duration_seconds >= 0),
  distance_km numeric(10,2) NOT NULL CHECK (distance_km >= 0),
  max_altitude_m integer,
  average_speed_kmh numeric(8,2),
  max_speed_kmh numeric(8,2),
  takeoff_lat double precision,
  takeoff_lon double precision,
  landing_lat double precision,
  landing_lon double precision,
  track_points jsonb NOT NULL DEFAULT '[]'::jsonb,
  igc_filename text NOT NULL,
  igc_checksum text NOT NULL,
  igc_content text NOT NULL,
  signature_present boolean NOT NULL DEFAULT false,
  public boolean NOT NULL DEFAULT false,
  imported_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (pilot_id, igc_checksum)
);

CREATE INDEX IF NOT EXISTS external_flights_pilot_flown_idx
  ON external_flights (pilot_id, flown_at DESC);

REVOKE ALL ON pilot_external_profiles, external_flights FROM web_anon;
GRANT ALL ON pilot_external_profiles, external_flights TO web_service;

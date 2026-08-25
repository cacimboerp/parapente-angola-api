ALTER TABLE platform_users ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE platform_users ADD COLUMN IF NOT EXISTS phone_confirmed_at timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS platform_users_phone_unique
  ON platform_users (phone) WHERE phone IS NOT NULL;

CREATE TABLE IF NOT EXISTS platform_signup_challenges (
  id uuid PRIMARY KEY,
  channel text NOT NULL CHECK (channel IN ('email', 'whatsapp')),
  contact text NOT NULL,
  email text,
  phone text,
  name text NOT NULL,
  password_hash text NOT NULL,
  code_hash text NOT NULL,
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS platform_signup_challenges_contact_created_idx
  ON platform_signup_challenges (contact, created_at DESC);

-- Creates 4 test accounts (one per dashboard-relevant role) directly in the
-- production Supabase Postgres database. Run this in the Supabase SQL editor.
--
-- Password for all 4 accounts: Sahali2026!Test
-- (bcrypt hash below was generated with this app's own hash_password() —
-- passlib CryptContext(schemes=["bcrypt"]) — so it verifies correctly.)
--
-- Safe to re-run: ON CONFLICT (email) DO NOTHING means it will never
-- overwrite an existing account if one of these emails somehow already
-- exists — it just skips that row silently.
--
-- Adjust 'Tunis' below if that municipality doesn't exist in prod, or swap
-- in whichever municipality name you want the scoped accounts tied to.

INSERT INTO users (id, email, password_hash, full_name, role, municipality_id, preferred_language, is_active, created_at)
VALUES
  (
    gen_random_uuid(),
    'test.superadmin@sahali.tn',
    '$2b$12$u49BwzuAEymwvcYIDqFQA.aDYBDs6MBmtb0m3nHAeWTk9FloN7Hy2',
    'Test SuperAdmin',
    'admin',
    NULL,
    'fr',
    true,
    now()
  ),
  (
    gen_random_uuid(),
    'test.municipaladmin@sahali.tn',
    '$2b$12$u49BwzuAEymwvcYIDqFQA.aDYBDs6MBmtb0m3nHAeWTk9FloN7Hy2',
    'Test Municipal Admin',
    'admin',
    (SELECT id FROM municipalities WHERE name = 'Tunis' LIMIT 1),
    'fr',
    true,
    now()
  ),
  (
    gen_random_uuid(),
    'test.analyst@sahali.tn',
    '$2b$12$u49BwzuAEymwvcYIDqFQA.aDYBDs6MBmtb0m3nHAeWTk9FloN7Hy2',
    'Test Analyst',
    'analyst',
    (SELECT id FROM municipalities WHERE name = 'Tunis' LIMIT 1),
    'fr',
    true,
    now()
  ),
  (
    gen_random_uuid(),
    'test.fieldagent@sahali.tn',
    '$2b$12$u49BwzuAEymwvcYIDqFQA.aDYBDs6MBmtb0m3nHAeWTk9FloN7Hy2',
    'Test Field Agent',
    'field_agent',
    (SELECT id FROM municipalities WHERE name = 'Tunis' LIMIT 1),
    'fr',
    true,
    now()
  )
ON CONFLICT (email) DO NOTHING
RETURNING id, email, role, municipality_id;

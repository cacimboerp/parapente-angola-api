CREATE OR REPLACE FUNCTION public.sync_platform_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE platform_users
  SET role = CASE lower(COALESCE(NEW.role, 'client'))
    WHEN 'admin' THEN 'admin'
    WHEN 'pilot' THEN 'pilot'
    WHEN 'provider' THEN 'provider'
    WHEN 'student' THEN 'student'
    WHEN 'aluno' THEN 'aluno'
    ELSE 'client'
  END,
  updated_at = now()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

UPDATE platform_users AS users
SET role = CASE lower(COALESCE(profiles.role, 'client'))
  WHEN 'admin' THEN 'admin'
  WHEN 'pilot' THEN 'pilot'
  WHEN 'provider' THEN 'provider'
  WHEN 'student' THEN 'student'
  WHEN 'aluno' THEN 'aluno'
  ELSE 'client'
END,
updated_at = now()
FROM profiles
WHERE users.id = profiles.id;

DROP TRIGGER IF EXISTS sync_platform_user_role_trigger ON profiles;
CREATE TRIGGER sync_platform_user_role_trigger
AFTER INSERT OR UPDATE OF role ON profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_platform_user_role();

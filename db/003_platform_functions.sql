CREATE OR REPLACE FUNCTION public.get_active_pilots_and_students()
RETURNS TABLE(id uuid, name text, level text, face_photo_url text, location text)
LANGUAGE sql STABLE AS $$
  SELECT p.id,p.name,p.level,p.face_photo_url,p.location
  FROM public.profiles p
  WHERE p.role IN ('pilot','aluno','student') AND p.status='active';
$$;

CREATE OR REPLACE FUNCTION public.get_public_pilot_profile(pilot_id_param uuid)
RETURNS TABLE(id uuid,name text,role text,status text,level text,location text,flight_hours integer,
  license_validity date,face_photo_url text,full_body_photo_url text,in_flight_photo_url text,verified boolean,cv text)
LANGUAGE sql STABLE AS $$
  SELECT p.id,p.name,p.role,p.status,p.level,p.location,p.flight_hours,p.license_validity,
    p.face_photo_url,p.full_body_photo_url,p.in_flight_photo_url,p.verified,p.cv
  FROM public.profiles p
  WHERE p.id=pilot_id_param AND p.role IN ('pilot','aluno','student') AND p.status='active' LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_emails()
RETURNS TABLE(email text)
LANGUAGE sql STABLE AS $$
  SELECT u.email FROM public.platform_users u
  JOIN public.profiles p ON p.id=u.id WHERE p.role='admin' AND p.status='active';
$$;

CREATE OR REPLACE FUNCTION public.get_all_users_with_details()
RETURNS TABLE(id uuid,name text,email text,role text,nif text,status text,level text,flight_hours integer,
  license_validity date,face_photo_url text,verified boolean)
LANGUAGE sql STABLE AS $$
  SELECT p.id,p.name,u.email,p.role,p.nif,p.status,p.level,p.flight_hours,p.license_validity,p.face_photo_url,p.verified
  FROM public.profiles p JOIN public.platform_users u ON u.id=p.id;
$$;

CREATE OR REPLACE FUNCTION public.get_user_email_by_id(user_id_param uuid)
RETURNS TABLE(email text)
LANGUAGE sql STABLE AS $$ SELECT u.email FROM public.platform_users u WHERE u.id=user_id_param; $$;

CREATE OR REPLACE FUNCTION public.get_pilot_commissions(start_date date,end_date date)
RETURNS TABLE(piloto_id uuid,pilot_name text,data_evento date,valor_pago numeric,commission_percent numeric,comissao numeric)
LANGUAGE sql STABLE AS $$
  SELECT p.id,p.name,pel.data_evento,pel.valor_pago,p.commission_percent,
    pel.valor_pago*(p.commission_percent/100)
  FROM public.pilot_event_log pel JOIN public.profiles p ON p.id=pel.piloto_id
  WHERE pel.data_evento BETWEEN start_date AND end_date AND p.role='pilot'
    AND pel.valor_pago IS NOT NULL AND p.commission_percent IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.get_active_pilots_and_students() TO web_anon,web_service;
GRANT EXECUTE ON FUNCTION public.get_public_pilot_profile(uuid) TO web_anon,web_service;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO web_service;

-- Generated from the confidential recovery schema. Contains structure only, never data.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS "public"."activities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "location_id" "uuid",
    "duration_minutes" integer,
    "price" numeric(10,2),
    "images" "text"[],
    "available_dates" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."activity_bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "activity_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "booking_date" "date" NOT NULL,
    "booking_time" time without time zone,
    "number_of_people" integer NOT NULL,
    "total_price" numeric(10,2),
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "client_details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."activity_vouchers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "activity_id" "uuid",
    "discount_type" "text" NOT NULL,
    "discount_value" numeric NOT NULL,
    "expiry_date" "date",
    "is_active" boolean DEFAULT true,
    "usage_limit" integer,
    "times_used" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."booking_extras" (
    "booking_id" "uuid" NOT NULL,
    "extra_id" "uuid" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_id" "uuid" NOT NULL,
    "provider_id" "uuid",
    "location_id" "uuid" NOT NULL,
    "booking_date" "date" NOT NULL,
    "booking_time" time without time zone NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "total_price" numeric(10,2),
    "client_details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "booking_code" "text",
    "payment_status" "text" DEFAULT 'unpaid'::"text",
    "proforma_sent" boolean DEFAULT false,
    "voucher_id" "uuid",
    "discount_amount" numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "public"."equipment" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "type_id" "uuid",
    "purchase_date" "date",
    "total_hours" numeric(10,2) DEFAULT 0,
    "status" "text" DEFAULT 'operacional'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "brand" "text",
    "model" "text",
    "image1_url" "text",
    "image2_url" "text",
    "image3_url" "text",
    "maintenance_history" "jsonb",
    "flight_history" "jsonb"
);

CREATE TABLE IF NOT EXISTS "public"."equipment_types" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."erp_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "setting_key" "text" NOT NULL,
    "setting_value" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."extras" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "price" numeric(10,2) NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "sku" "text"
);

CREATE TABLE IF NOT EXISTS "public"."flight_evaluations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "flight_log_id" "uuid",
    "booking_id" "uuid",
    "rating_flight" smallint,
    "rating_landing" smallint,
    "rating_location" smallint,
    "rating_turbulence" smallint,
    "rating_overall" smallint,
    "observation" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."flight_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pilot_id" "uuid" NOT NULL,
    "flight_date" "date" NOT NULL,
    "duration_minutes" integer,
    "location_id" "uuid",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "booking_id" "uuid",
    "max_altitude" integer,
    "wind_speed" integer,
    "temperature" integer,
    "landing_spot" "text",
    "landing_smoothness" smallint,
    "incidents" "text",
    "sightings" "text",
    "flight_type" "text",
    "equipment_used" "jsonb",
    "satisfaction_rating" smallint,
    "photo_code" "text",
    "photo_urls" "jsonb"
);

CREATE TABLE IF NOT EXISTS "public"."flight_zones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "lat" numeric NOT NULL,
    "lon" numeric NOT NULL,
    "altitude" "text",
    "ideal_conditions" "text",
    "img_desc" "text",
    "images" "jsonb",
    "price" numeric DEFAULT 0,
    "flight_time" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "available_dates" "jsonb",
    "sku" "text",
    "time_slots" "jsonb",
    "ideal_wind_directions" "text"[]
);

CREATE TABLE IF NOT EXISTS "public"."gallery_images" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "image_url" "text" NOT NULL,
    "location_id" "uuid",
    "pilot_id" "uuid",
    "uploaded_by" "uuid",
    "upload_date" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."licencas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "piloto_id" "uuid",
    "nome_completo" "text" NOT NULL,
    "data_nascimento" "date",
    "numero_identificacao" "text",
    "endereco" "text",
    "nacionalidade" "text",
    "data_emissao" "date" NOT NULL,
    "data_validade" "date" NOT NULL,
    "nivel_certificacao" "text",
    "numero_horas_voo" integer,
    "escola_treinamento" "text",
    "assinatura_piloto" "text",
    "assinatura_instrutor" "text",
    "condicoes_medicas" "text",
    "apolice" "text",
    "tipo_cobertura" "text",
    "observacoes_especiais" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "numero_licenca" integer,
    "created_by_user_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."payment_methods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."pilot_event_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "piloto_id" "uuid" NOT NULL,
    "tipo_evento_id" "uuid",
    "descricao" "text",
    "data_evento" "date" NOT NULL,
    "hora_evento" time without time zone,
    "nivel_no_momento" "text",
    "horas_de_voo" numeric(10,2),
    "instrutor_id" "uuid",
    "observacoes" "text",
    "anexo_url" "text",
    "anexo_tipo" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "valor_pago" numeric
);

CREATE TABLE IF NOT EXISTS "public"."pilot_event_types" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "cor" "text",
    "icone" "text",
    "exige_instrutor" boolean DEFAULT false,
    "exige_anexo" boolean DEFAULT false,
    "ativo" boolean DEFAULT true,
    "ordem_visualizacao" integer DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "name" "text",
    "role" "text" DEFAULT 'client'::"text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "cv" "text",
    "location" "text",
    "flight_hours" integer,
    "license_validity" "date",
    "level" "text",
    "fai_id" "text",
    "xc_portugal_id" "text",
    "face_photo_url" "text",
    "full_body_photo_url" "text",
    "in_flight_photo_url" "text",
    "level_history" "jsonb",
    "price" numeric,
    "verified" boolean DEFAULT false,
    "license_number" "text",
    "emergency_contact_name" "text",
    "emergency_contact_phone" "text",
    "phone" "text",
    "commission_percent" numeric(5,2),
    "fai_certificate_url" "text",
    "license_certificate_url" "text",
    "pilot_lic_ao" "text",
    "nif" "text"
);

CREATE TABLE IF NOT EXISTS "public"."receipt_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receipt_id" "uuid" NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "description" "text" NOT NULL,
    "amount" numeric(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."receipt_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receipt_id" "uuid" NOT NULL,
    "payment_method_id" "uuid" NOT NULL,
    "amount" numeric NOT NULL,
    "payment_date" "date" DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "type" "text" DEFAULT 'payment'::"text" NOT NULL,
    "notes" "text"
);

CREATE TABLE IF NOT EXISTS "public"."receipts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_id" "uuid",
    "issue_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "total_amount" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "status" "text" DEFAULT 'pending'::"text"
);

CREATE TABLE IF NOT EXISTS "public"."sponsors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "nif" "text",
    "logo_url" "text",
    "show_on_main_page" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "url" "text"
);

CREATE TABLE IF NOT EXISTS "public"."sponsorship_pilot_allocations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sponsorship_id" "uuid" NOT NULL,
    "pilot_id" "uuid" NOT NULL,
    "percentage" numeric(5,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "sponsorship_pilot_allocations_percentage_check" CHECK ((("percentage" >= (0)::numeric) AND ("percentage" <= (100)::numeric)))
);

CREATE TABLE IF NOT EXISTS "public"."sponsorships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sponsor_id" "uuid" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date",
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."training_participants" (
    "training_id" "uuid" NOT NULL,
    "participant_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'enrolled'::"text",
    "completion_date" "date"
);

CREATE TABLE IF NOT EXISTS "public"."trainings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "start_date" "date",
    "end_date" "date",
    "instructor_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."vouchers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "discount_type" "text" NOT NULL,
    "discount_value" numeric NOT NULL,
    "expiry_date" "date",
    "is_active" boolean DEFAULT true NOT NULL,
    "usage_limit" integer,
    "times_used" integer DEFAULT 0 NOT NULL,
    "min_booking_value" numeric,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."activity_bookings"
    ADD CONSTRAINT "activity_bookings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."activity_vouchers"
    ADD CONSTRAINT "activity_vouchers_code_key" UNIQUE ("code");

ALTER TABLE ONLY "public"."activity_vouchers"
    ADD CONSTRAINT "activity_vouchers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."booking_extras"
    ADD CONSTRAINT "booking_extras_pkey" PRIMARY KEY ("booking_id", "extra_id");

ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."equipment"
    ADD CONSTRAINT "equipment_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."equipment_types"
    ADD CONSTRAINT "equipment_types_name_key" UNIQUE ("name");

ALTER TABLE ONLY "public"."equipment_types"
    ADD CONSTRAINT "equipment_types_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."erp_settings"
    ADD CONSTRAINT "erp_settings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."erp_settings"
    ADD CONSTRAINT "erp_settings_setting_key_key" UNIQUE ("setting_key");

ALTER TABLE ONLY "public"."extras"
    ADD CONSTRAINT "extras_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."flight_evaluations"
    ADD CONSTRAINT "flight_evaluations_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."flight_logs"
    ADD CONSTRAINT "flight_logs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."flight_zones"
    ADD CONSTRAINT "flight_zones_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."gallery_images"
    ADD CONSTRAINT "gallery_images_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."licencas"
    ADD CONSTRAINT "licencas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pilot_event_log"
    ADD CONSTRAINT "pilot_event_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pilot_event_types"
    ADD CONSTRAINT "pilot_event_types_codigo_key" UNIQUE ("codigo");

ALTER TABLE ONLY "public"."pilot_event_types"
    ADD CONSTRAINT "pilot_event_types_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."receipt_items"
    ADD CONSTRAINT "receipt_items_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."receipt_payments"
    ADD CONSTRAINT "receipt_payments_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."receipts"
    ADD CONSTRAINT "receipts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sponsors"
    ADD CONSTRAINT "sponsors_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sponsorship_pilot_allocations"
    ADD CONSTRAINT "sponsorship_pilot_allocations_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sponsorship_pilot_allocations"
    ADD CONSTRAINT "sponsorship_pilot_allocations_sponsorship_id_pilot_id_key" UNIQUE ("sponsorship_id", "pilot_id");

ALTER TABLE ONLY "public"."sponsorships"
    ADD CONSTRAINT "sponsorships_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."training_participants"
    ADD CONSTRAINT "training_participants_pkey" PRIMARY KEY ("training_id", "participant_id");

ALTER TABLE ONLY "public"."trainings"
    ADD CONSTRAINT "trainings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_code_key" UNIQUE ("code");

ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."flight_zones"("id");

ALTER TABLE ONLY "public"."activity_bookings"
    ADD CONSTRAINT "activity_bookings_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "public"."activities"("id");

ALTER TABLE ONLY "public"."activity_bookings"
    ADD CONSTRAINT "activity_bookings_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."activity_vouchers"
    ADD CONSTRAINT "activity_vouchers_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "public"."activities"("id");

ALTER TABLE ONLY "public"."booking_extras"
    ADD CONSTRAINT "booking_extras_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."booking_extras"
    ADD CONSTRAINT "booking_extras_extra_id_fkey" FOREIGN KEY ("extra_id") REFERENCES "public"."extras"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."flight_zones"("id");

ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_voucher_id_fkey" FOREIGN KEY ("voucher_id") REFERENCES "public"."vouchers"("id");

ALTER TABLE ONLY "public"."equipment"
    ADD CONSTRAINT "equipment_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "public"."equipment_types"("id");

ALTER TABLE ONLY "public"."flight_evaluations"
    ADD CONSTRAINT "flight_evaluations_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."flight_evaluations"
    ADD CONSTRAINT "flight_evaluations_flight_log_id_fkey" FOREIGN KEY ("flight_log_id") REFERENCES "public"."flight_logs"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."flight_logs"
    ADD CONSTRAINT "flight_logs_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."flight_logs"
    ADD CONSTRAINT "flight_logs_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."flight_zones"("id");

ALTER TABLE ONLY "public"."flight_logs"
    ADD CONSTRAINT "flight_logs_pilot_id_fkey" FOREIGN KEY ("pilot_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."gallery_images"
    ADD CONSTRAINT "gallery_images_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."flight_zones"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."gallery_images"
    ADD CONSTRAINT "gallery_images_pilot_id_fkey" FOREIGN KEY ("pilot_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."gallery_images"
    ADD CONSTRAINT "gallery_images_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."platform_users"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."licencas"
    ADD CONSTRAINT "licencas_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."licencas"
    ADD CONSTRAINT "licencas_piloto_id_fkey" FOREIGN KEY ("piloto_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."pilot_event_log"
    ADD CONSTRAINT "pilot_event_log_instrutor_id_fkey" FOREIGN KEY ("instrutor_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."pilot_event_log"
    ADD CONSTRAINT "pilot_event_log_piloto_id_fkey" FOREIGN KEY ("piloto_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."pilot_event_log"
    ADD CONSTRAINT "pilot_event_log_tipo_evento_id_fkey" FOREIGN KEY ("tipo_evento_id") REFERENCES "public"."pilot_event_types"("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."platform_users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."receipt_items"
    ADD CONSTRAINT "receipt_items_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id");

ALTER TABLE ONLY "public"."receipt_items"
    ADD CONSTRAINT "receipt_items_receipt_id_fkey" FOREIGN KEY ("receipt_id") REFERENCES "public"."receipts"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."receipt_payments"
    ADD CONSTRAINT "receipt_payments_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."payment_methods"("id");

ALTER TABLE ONLY "public"."receipt_payments"
    ADD CONSTRAINT "receipt_payments_receipt_id_fkey" FOREIGN KEY ("receipt_id") REFERENCES "public"."receipts"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."receipts"
    ADD CONSTRAINT "receipts_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."sponsorship_pilot_allocations"
    ADD CONSTRAINT "sponsorship_pilot_allocations_pilot_id_fkey" FOREIGN KEY ("pilot_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."sponsorship_pilot_allocations"
    ADD CONSTRAINT "sponsorship_pilot_allocations_sponsorship_id_fkey" FOREIGN KEY ("sponsorship_id") REFERENCES "public"."sponsorships"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."sponsorships"
    ADD CONSTRAINT "sponsorships_sponsor_id_fkey" FOREIGN KEY ("sponsor_id") REFERENCES "public"."sponsors"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."training_participants"
    ADD CONSTRAINT "training_participants_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."training_participants"
    ADD CONSTRAINT "training_participants_training_id_fkey" FOREIGN KEY ("training_id") REFERENCES "public"."trainings"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."trainings"
    ADD CONSTRAINT "trainings_instructor_id_fkey" FOREIGN KEY ("instructor_id") REFERENCES "public"."profiles"("id");

CREATE INDEX IF NOT EXISTS "idx_bookings_booking_code" ON "public"."bookings" USING "btree" ("booking_code");

CREATE UNIQUE INDEX IF NOT EXISTS "licencas_numero_licenca_key" ON "public"."licencas" USING "btree" ("numero_licenca");

GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;

GRANT ALL ON ALL TABLES IN SCHEMA public TO web_service;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_service;


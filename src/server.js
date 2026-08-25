import http from 'node:http';
import { readFile, readdir } from 'node:fs/promises';
import { randomBytes, randomInt, randomUUID, createHash, timingSafeEqual } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { SignJWT, jwtVerify } from 'jose';
import pg from 'pg';

const { Pool } = pg;
const port = Number(process.env.PORT || 8080);
const databaseUrl = required('DATABASE_URL');
const jwtSecretValue = required('JWT_SECRET', 32);
const jwtSecret = new TextEncoder().encode(jwtSecretValue);
const migrationToken = process.env.MIGRATION_TOKEN || '';
const postgrestUrl = process.env.POSTGREST_URL || 'http://postgrest:3000';
const smtpEndpoint = process.env.SMTP_ENDPOINT || '';
const whatsappEndpoint = process.env.WHATSAPP_ENDPOINT || 'https://cacimboerp.cacimboweb.com/api/send-message-whatsapp';
const frontendUrl = (process.env.FRONTEND_URL || 'https://www.parapenteangola.com').replace(/\/+$/, '');
const allowedOrigins = new Set((process.env.CORS_ORIGINS || '')
  .split(',').map((item) => item.trim()).filter(Boolean));
const pool = new Pool({ connectionString: databaseUrl, max: 10 });

const publicReadTables = new Set([
  'activities', 'equipment_types', 'extras', 'flight_zones', 'gallery_images',
  'payment_methods', 'pilot_event_types', 'sponsors', 'trainings',
]);
const clientWriteTables = new Set(['activity_bookings', 'bookings', 'booking_extras', 'profiles']);
const pilotWriteTables = new Set(['flight_logs', 'flight_evaluations', 'pilot_event_log', 'profiles']);
const publicRpcs = new Set(['get_active_pilots_and_students', 'get_public_pilot_profile']);
const authenticatedRpcs = new Set(['get_admin_emails']);
const pilotRpcs = new Set(['get_pilot_commissions']);
const importTables = new Set([
  'activities', 'activity_bookings', 'activity_vouchers', 'booking_extras', 'bookings',
  'equipment', 'equipment_types', 'erp_settings', 'extras', 'flight_evaluations',
  'flight_logs', 'flight_zones', 'gallery_images', 'licencas', 'payment_methods',
  'pilot_event_log', 'pilot_event_types', 'profiles', 'receipt_items', 'receipt_payments',
  'receipts', 'sponsors', 'sponsorship_pilot_allocations', 'sponsorships',
  'training_participants', 'trainings', 'vouchers', 'platform_users',
]);

function required(name, minLength = 1) {
  const value = process.env[name] || '';
  if (value.length < minLength) throw new Error(`${name} is required and must contain at least ${minLength} characters`);
  return value;
}

function corsHeaders(origin) {
  const allowed = origin && (allowedOrigins.has(origin) || allowedOrigins.has('*'));
  return {
    ...(allowed ? { 'Access-Control-Allow-Origin': origin, Vary: 'Origin' } : {}),
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey, prefer, range, x-platform-project',
    'Access-Control-Allow-Methods': 'GET,HEAD,POST,PATCH,PUT,DELETE,OPTIONS',
    'Access-Control-Expose-Headers': 'content-range, preference-applied',
  };
}

function send(res, status, payload, headers = {}) {
  const body = payload === undefined ? '' : JSON.stringify(payload);
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', ...headers });
  res.end(body);
}

async function jsonBody(req, limit = 2_000_000) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limit) throw Object.assign(new Error('Payload too large'), { status: 413 });
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw Object.assign(new Error('Invalid JSON body'), { status: 400 }); }
}

function bearer(req) {
  const match = /^Bearer\s+(.+)$/i.exec(req.headers.authorization || '');
  return match?.[1] || null;
}

async function authenticate(req, optional = false) {
  const token = bearer(req);
  if (!token) {
    if (optional) return null;
    throw Object.assign(new Error('Authentication required'), { status: 401 });
  }
  try {
    const { payload } = await jwtVerify(token, jwtSecret, { issuer: 'parapente-angola-api', audience: 'parapente-angola' });
    return payload;
  } catch {
    throw Object.assign(new Error('Invalid or expired token'), { status: 401 });
  }
}

async function issueSession(user) {
  const accessToken = await new SignJWT({ role: user.role || 'client', email: user.email })
    .setProtectedHeader({ alg: 'HS256' }).setSubject(user.id)
    .setIssuer('parapente-angola-api').setAudience('parapente-angola')
    .setIssuedAt().setExpirationTime('1h').sign(jwtSecret);
  const refreshToken = randomBytes(48).toString('base64url');
  const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
  await pool.query(
    `INSERT INTO platform_refresh_tokens (token_hash, user_id, expires_at)
     VALUES ($1, $2, now() + interval '30 days')`,
    [tokenHash, user.id],
  );
  const profile = await pool.query('SELECT * FROM profiles WHERE id = $1', [user.id]);
  return {
    access_token: accessToken, refresh_token: refreshToken, token_type: 'bearer', expires_in: 3600,
    user: {
      id: user.id,
      email: user.email?.endsWith('@whatsapp.parapenteangola.invalid') ? '' : user.email,
      phone: user.phone || profile.rows[0]?.phone || '',
      role: user.role || 'client',
      user_metadata: { name: profile.rows[0]?.name || user.name || '' },
    },
  };
}

async function signUp(req, res, headers) {
  const body = await jsonBody(req);
  const channel = body.channel === 'whatsapp' ? 'whatsapp' : 'email';
  const email = channel === 'email' ? String(body.email || body.contact || '').trim().toLowerCase() : '';
  const phone = channel === 'whatsapp' ? normalizePhone(body.phone || body.contact) : '';
  const contact = channel === 'email' ? email : phone;
  const password = String(body.password || '');
  const name = String(body.options?.data?.name || body.name || '').trim();
  if (!name || password.length < 8 || (channel === 'email' && !/^\S+@\S+\.\S+$/.test(email)) || (channel === 'whatsapp' && !/^2449\d{8}$/.test(phone))) {
    return send(res, 422, { message: 'Preencha um nome, um contacto válido e uma palavra-passe com pelo menos 8 caracteres.' }, headers);
  }
  const existing = channel === 'email'
    ? await pool.query('SELECT 1 FROM platform_users WHERE lower(email)=lower($1)', [email])
    : await pool.query("SELECT 1 FROM profiles WHERE regexp_replace(COALESCE(phone,''),'\\D','','g')=$1", [phone]);
  if (existing.rowCount) return send(res, 409, { message: 'Já existe uma conta com este contacto.' }, headers);

  const recent = await pool.query(
    `SELECT count(*)::int AS total FROM platform_signup_challenges
     WHERE contact=$1 AND created_at > now() - interval '15 minutes'`, [contact],
  );
  if (recent.rows[0].total >= 3) return send(res, 429, { message: 'Aguarde alguns minutos antes de pedir outro código.' }, headers);

  const challengeId = randomUUID();
  const code = String(randomInt(100000, 1000000));
  const passwordHash = await bcrypt.hash(password, 12);
  const codeHash = signupCodeHash(challengeId, code);
  await pool.query('DELETE FROM platform_signup_challenges WHERE expires_at<=now()');
  await pool.query(
    `INSERT INTO platform_signup_challenges
      (id,channel,contact,email,phone,name,password_hash,code_hash,expires_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,now() + interval '10 minutes')`,
    [challengeId, channel, contact, email || null, phone || null, name, passwordHash, codeHash],
  );
  try {
    const message = `O seu código de confirmação Parapente Angola é ${code}. Expira em 10 minutos.`;
    if (channel === 'email') {
      await sendEmail(email, 'Confirmar registo — Parapente Angola', `<p>${message}</p><p>Se não pediu este registo, ignore esta mensagem.</p>`, challengeId);
    } else {
      await sendWhatsApp(phone, message);
    }
    return send(res, 200, { data: { challenge_id: challengeId, verification_required: true, channel, contact_hint: maskContact(channel, contact), expires_in: 600 }, error: null }, headers);
  } catch (error) {
    await pool.query('DELETE FROM platform_signup_challenges WHERE id=$1', [challengeId]);
    console.error(`Failed to deliver signup code through ${channel}:`, error.message);
    return send(res, 502, { message: channel === 'email' ? 'Não foi possível enviar o email de confirmação.' : 'Não foi possível enviar o código pelo WhatsApp.' }, headers);
  }
}

function normalizePhone(value) {
  let digits = String(value || '').replace(/\D/g, '');
  if (digits.startsWith('00244')) digits = digits.slice(2);
  if (digits.length === 9 && digits.startsWith('9')) digits = `244${digits}`;
  return digits;
}

function signupCodeHash(challengeId, code) {
  return createHash('sha256').update(`${challengeId}:${code}:${jwtSecretValue}`).digest('hex');
}

function maskContact(channel, contact) {
  if (channel === 'whatsapp') return `${contact.slice(0, 5)}***${contact.slice(-3)}`;
  const [local, domain] = contact.split('@');
  return `${local.slice(0, 2)}***@${domain}`;
}

async function verifySignUp(req, res, headers) {
  const body = await jsonBody(req);
  const challengeId = String(body.challenge_id || '');
  const code = String(body.code || '').replace(/\D/g, '');
  const challengeResult = await pool.query(
    'SELECT * FROM platform_signup_challenges WHERE id=$1 AND expires_at>now() FOR UPDATE', [challengeId],
  );
  const challenge = challengeResult.rows[0];
  if (!challenge || challenge.attempts >= 5) return send(res, 400, { message: 'O código é inválido ou expirou.' }, headers);
  const suppliedHash = Buffer.from(signupCodeHash(challengeId, code), 'hex');
  const expectedHash = Buffer.from(challenge.code_hash, 'hex');
  if (suppliedHash.length !== expectedHash.length || !timingSafeEqual(suppliedHash, expectedHash)) {
    await pool.query('UPDATE platform_signup_challenges SET attempts=attempts+1 WHERE id=$1', [challengeId]);
    return send(res, 400, { message: 'O código introduzido não está correto.' }, headers);
  }

  const id = randomUUID();
  const storedEmail = challenge.email || `${challenge.phone}@whatsapp.parapenteangola.invalid`;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [challenge.contact]);
    const created = await client.query(
      `INSERT INTO platform_users (id,email,phone,password_hash,role,email_confirmed_at,phone_confirmed_at)
       VALUES ($1,$2,$3,$4,'client',$5,$6) RETURNING id,email,phone,role`,
      [id, storedEmail, challenge.phone, challenge.password_hash, challenge.email ? new Date() : null, challenge.phone ? new Date() : null],
    );
    await client.query(
      `INSERT INTO profiles (id,name,phone,role,status) VALUES ($1,$2,$3,'client','active')`,
      [id, challenge.name, challenge.phone],
    );
    await client.query('DELETE FROM platform_signup_challenges WHERE id=$1', [challengeId]);
    await client.query('COMMIT');
    return send(res, 200, { data: await issueSession(created.rows[0]), error: null }, headers);
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.code === '23505') return send(res, 409, { message: 'Já existe uma conta com este contacto.' }, headers);
    throw error;
  } finally { client.release(); }
}

async function signIn(req, res, headers) {
  const body = await jsonBody(req);
  const identifier = String(body.identifier || body.email || '').trim().toLowerCase();
  const phone = normalizePhone(identifier);
  const result = await pool.query(
    `SELECT u.*, COALESCE(p.role,u.role,'client') AS effective_role, p.status
     FROM platform_users u LEFT JOIN profiles p ON p.id=u.id
     WHERE lower(u.email)=lower($1) OR ($2 <> '' AND regexp_replace(COALESCE(u.phone,p.phone,''),'\\D','','g')=$2)`, [identifier, phone],
  );
  const user = result.rows[0];
  if (!user || !user.password_hash || !(await bcrypt.compare(String(body.password || ''), user.password_hash))) {
    return send(res, 400, { message: 'Email ou palavra-passe incorretos.' }, headers);
  }
  if (user.status === 'suspended' || user.status === 'inactive') {
    return send(res, 403, { message: 'Esta conta não está ativa.' }, headers);
  }
  user.role = user.effective_role;
  await pool.query('UPDATE platform_users SET last_sign_in_at=now(), updated_at=now() WHERE id=$1', [user.id]);
  return send(res, 200, { data: await issueSession(user), error: null }, headers);
}

async function refresh(req, res, headers) {
  const body = await jsonBody(req);
  const raw = String(body.refresh_token || '');
  const hash = createHash('sha256').update(raw).digest('hex');
  const result = await pool.query(
    `DELETE FROM platform_refresh_tokens r USING platform_users u
     WHERE r.token_hash=$1 AND r.user_id=u.id AND r.expires_at>now()
     RETURNING u.id,u.email,u.role`, [hash],
  );
  if (!result.rows[0]) return send(res, 401, { message: 'Sessão expirada.' }, headers);
  return send(res, 200, { data: await issueSession(result.rows[0]), error: null }, headers);
}

async function currentUser(req, res, headers) {
  const auth = await authenticate(req);
  const result = await pool.query(
    `SELECT u.id,u.email,COALESCE(p.role,u.role,'client') AS role,u.created_at
     FROM platform_users u LEFT JOIN profiles p ON p.id=u.id WHERE u.id=$1`, [auth.sub],
  );
  return send(res, 200, { data: { user: result.rows[0] || null }, error: null }, headers);
}

async function sendEmail(to, subject, html, subjectId) {
  if (!smtpEndpoint) throw new Error('SMTP endpoint is not configured');
  const token = await new SignJWT({ role: 'system', email: to })
    .setProtectedHeader({ alg: 'HS256' }).setSubject(subjectId)
    .setIssuer('parapente-angola-api').setAudience('parapente-angola')
    .setIssuedAt().setExpirationTime('5m').sign(jwtSecret);
  const response = await fetch(smtpEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ to, subject, html }),
  });
  if (!response.ok) throw new Error(`SMTP endpoint returned ${response.status}`);
}

async function sendWhatsApp(phone, message) {
  if (!whatsappEndpoint) throw new Error('WhatsApp endpoint is not configured');
  const response = await fetch(whatsappEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message_body: message, number: phone, country: 'AO', country_code: '244' }),
  });
  if (!response.ok) throw new Error(`Cacimbo WhatsApp endpoint returned ${response.status}`);
}

async function recoverPassword(req, res, headers) {
  const body = await jsonBody(req);
  const email = String(body.email || '').trim().toLowerCase();
  const result = await pool.query('SELECT id,email FROM platform_users WHERE lower(email)=lower($1)', [email]);
  const user = result.rows[0];
  if (user) {
    const raw = randomBytes(40).toString('base64url');
    const hash = createHash('sha256').update(raw).digest('hex');
    await pool.query('DELETE FROM platform_password_resets WHERE user_id=$1 OR expires_at<=now()', [user.id]);
    await pool.query(
      `INSERT INTO platform_password_resets (token_hash,user_id,expires_at)
       VALUES ($1,$2,now() + interval '30 minutes')`, [hash, user.id],
    );
    const resetUrl = `${frontendUrl}/reset-password?token=${encodeURIComponent(raw)}`;
    try {
      await sendEmail(
        user.email,
        'Redefinir palavra-passe — Parapente Angola',
        `<p>Recebemos um pedido para redefinir a sua palavra-passe.</p><p><a href="${resetUrl}">Criar nova palavra-passe</a></p><p>Este link expira em 30 minutos.</p>`,
        user.id,
      );
    } catch (error) {
      console.error('Failed to send password recovery email:', error.message);
    }
  }
  return send(res, 200, { data: {}, error: null }, headers);
}

async function changePassword(req, res, headers) {
  const body = await jsonBody(req);
  const password = String(body.password || '');
  if (password.length < 8) return send(res, 422, { message: 'A palavra-passe deve ter pelo menos 8 caracteres.' }, headers);
  let userId;
  let resetHash;
  if (body.reset_token) {
    resetHash = createHash('sha256').update(String(body.reset_token)).digest('hex');
    const result = await pool.query(
      'SELECT user_id FROM platform_password_resets WHERE token_hash=$1 AND expires_at>now()', [resetHash],
    );
    userId = result.rows[0]?.user_id;
  } else {
    userId = (await authenticate(req)).sub;
  }
  if (!userId) return send(res, 401, { message: 'O link de recuperação é inválido ou expirou.' }, headers);
  const passwordHash = await bcrypt.hash(password, 12);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('UPDATE platform_users SET password_hash=$1,updated_at=now() WHERE id=$2', [passwordHash, userId]);
    await client.query('DELETE FROM platform_refresh_tokens WHERE user_id=$1', [userId]);
    if (resetHash) await client.query('DELETE FROM platform_password_resets WHERE token_hash=$1', [resetHash]);
    await client.query('COMMIT');
  } catch (error) { await client.query('ROLLBACK'); throw error; }
  finally { client.release(); }
  return send(res, 200, { data: {}, error: null }, headers);
}

function restTable(pathname) {
  const match = /^\/rest\/v1\/([a-zA-Z0-9_]+)/.exec(pathname);
  return match?.[1] || '';
}

function ownerColumn(role, table) {
  if (table === 'profiles') return 'id';
  if (role === 'client') return ({
    activity_bookings: 'client_id', bookings: 'client_id', receipts: 'client_id',
  })[table] || '';
  if (['pilot', 'provider'].includes(role)) return ({
    bookings: 'provider_id', flight_logs: 'pilot_id', pilot_event_log: 'piloto_id',
  })[table] || '';
  return '';
}

function scopedPayload(buffer, column, userId, table) {
  let parsed;
  try { parsed = JSON.parse(buffer.toString('utf8')); }
  catch { throw Object.assign(new Error('Invalid JSON body'), { status: 400 }); }
  const rows = Array.isArray(parsed) ? parsed : [parsed];
  for (const row of rows) {
    if (!row || typeof row !== 'object') throw Object.assign(new Error('Invalid JSON body'), { status: 400 });
    row[column] = userId;
    if (table === 'profiles') {
      for (const protectedField of ['role', 'status', 'verified', 'commission_percent']) delete row[protectedField];
    }
  }
  return Buffer.from(JSON.stringify(Array.isArray(parsed) ? rows : rows[0]));
}

async function verifyRelatedOwnership(role, table, buffer, userId) {
  let relation;
  if (role === 'client' && table === 'booking_extras') {
    relation = { source: 'booking_id', sql: 'SELECT id FROM bookings WHERE id = ANY($1::uuid[]) AND client_id = $2' };
  } else if (['pilot', 'provider'].includes(role) && table === 'flight_evaluations') {
    relation = { source: 'flight_log_id', sql: 'SELECT id FROM flight_logs WHERE id = ANY($1::uuid[]) AND pilot_id = $2' };
  } else {
    return;
  }
  let parsed;
  try { parsed = JSON.parse(buffer.toString('utf8')); }
  catch { throw Object.assign(new Error('Invalid JSON body'), { status: 400 }); }
  const rows = Array.isArray(parsed) ? parsed : [parsed];
  const ids = [...new Set(rows.map((row) => row?.[relation.source]).filter(Boolean))];
  if (!ids.length) throw Object.assign(new Error('Operação não autorizada.'), { status: 403 });
  const result = await pool.query(relation.sql, [ids, userId]);
  if (result.rowCount !== ids.length) throw Object.assign(new Error('Operação não autorizada.'), { status: 403 });
}

async function proxyRest(req, res, url, headers) {
  const table = restTable(url.pathname);
  const auth = await authenticate(req, req.method === 'GET' || req.method === 'HEAD');
  const role = auth?.role || 'anon';
  const isRpc = url.pathname.startsWith('/rest/v1/rpc/');
  const rpcName = isRpc ? url.pathname.slice('/rest/v1/rpc/'.length).split('/')[0] : '';
  const read = req.method === 'GET' || req.method === 'HEAD';
  const allowed = (isRpc && (
    role === 'admin'
    || publicRpcs.has(rpcName)
    || (role !== 'anon' && authenticatedRpcs.has(rpcName))
    || (['pilot', 'provider'].includes(role) && pilotRpcs.has(rpcName))
  )) || (!isRpc && (role === 'admin'
    || (read && (publicReadTables.has(table) || role !== 'anon'))
    || (!read && role === 'client' && clientWriteTables.has(table))
    || (!read && ['pilot', 'student', 'aluno', 'provider'].includes(role) && pilotWriteTables.has(table))));
  if (!allowed) return send(res, auth ? 403 : 401, { message: 'Operação não autorizada.' }, headers);

  const scopeColumn = auth && role !== 'admin' ? ownerColumn(role, table) : '';
  if (scopeColumn && read) url.searchParams.set(scopeColumn, `eq.${auth.sub}`);

  const upstreamHeaders = {};
  for (const key of ['content-type', 'prefer', 'range', 'accept', 'accept-profile', 'content-profile']) {
    if (req.headers[key]) upstreamHeaders[key] = req.headers[key];
  }
  upstreamHeaders.Authorization = `Bearer ${required('POSTGREST_SERVICE_TOKEN', 32)}`;
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  let requestBody = Buffer.concat(chunks);
  if (auth && role !== 'admin' && !read && !isRpc) {
    if (scopeColumn) {
      if (req.method !== 'POST') url.searchParams.set(scopeColumn, `eq.${auth.sub}`);
      requestBody = scopedPayload(requestBody, scopeColumn, auth.sub, table);
    } else {
      await verifyRelatedOwnership(role, table, requestBody, auth.sub);
    }
  }
  const response = await fetch(`${postgrestUrl}${url.pathname.replace('/rest/v1', '')}${url.search}`, {
    method: req.method, headers: upstreamHeaders,
    body: read ? undefined : requestBody,
  });
  const responseHeaders = { ...headers };
  for (const key of ['content-type', 'content-range', 'preference-applied']) {
    const value = response.headers.get(key); if (value) responseHeaders[key] = value;
  }
  res.writeHead(response.status, responseHeaders);
  res.end(Buffer.from(await response.arrayBuffer()));
}

async function importRows(req, res, headers) {
  if (!migrationToken || req.headers['x-migration-token'] !== migrationToken) {
    return send(res, 404, { message: 'Not found' }, headers);
  }
  const body = await jsonBody(req, 8_000_000);
  const table = String(body.table || '');
  const rows = Array.isArray(body.rows) ? body.rows : [];
  if (!importTables.has(table) || !rows.length || rows.length > 500) {
    return send(res, 422, { message: 'Invalid import batch' }, headers);
  }
  const columns = Object.keys(rows[0]);
  if (!columns.length || columns.some((column) => !/^[a-z_][a-z0-9_]*$/i.test(column))) {
    return send(res, 422, { message: 'Invalid columns' }, headers);
  }
  const values = [];
  const tuples = rows.map((row, rowIndex) => {
    if (Object.keys(row).join('|') !== columns.join('|')) throw Object.assign(new Error('Inconsistent import columns'), { status: 422 });
    return `(${columns.map((_, columnIndex) => {
      values.push(row[columns[columnIndex]]); return `$${rowIndex * columns.length + columnIndex + 1}`;
    }).join(',')})`;
  });
  const quoted = columns.map((column) => `"${column}"`).join(',');
  await pool.query(`INSERT INTO "${table}" (${quoted}) VALUES ${tuples.join(',')} ON CONFLICT DO NOTHING`, values);
  return send(res, 200, { imported: rows.length, table }, headers);
}

async function initializeDatabase() {
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    try {
      const directory = new URL('../db/', import.meta.url);
      const files = (await readdir(directory)).filter((name) => name.endsWith('.sql')).sort();
      await pool.query(`CREATE TABLE IF NOT EXISTS platform_schema_migrations (
        filename text PRIMARY KEY,
        applied_at timestamptz NOT NULL DEFAULT now()
      )`);
      const [{ rows: migrationRows }, { rows: initializedRows }] = await Promise.all([
        pool.query('SELECT filename FROM platform_schema_migrations'),
        pool.query("SELECT to_regclass('public.platform_users') IS NOT NULL AND to_regclass('public.profiles') IS NOT NULL AS initialized"),
      ]);
      const applied = new Set(migrationRows.map((row) => row.filename));
      if (!applied.size && initializedRows[0]?.initialized) {
        for (const file of files) {
          await pool.query('INSERT INTO platform_schema_migrations (filename) VALUES ($1) ON CONFLICT DO NOTHING', [file]);
          applied.add(file);
        }
      }
      for (const file of files) {
        if (applied.has(file)) continue;
        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          await client.query(await readFile(new URL(file, directory), 'utf8'));
          await client.query('INSERT INTO platform_schema_migrations (filename) VALUES ($1)', [file]);
          await client.query('COMMIT');
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
      }
      await pool.query("NOTIFY pgrst, 'reload schema'");
      return;
    }
    catch (error) {
      if (attempt === 30) throw error;
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }
  }
}

await initializeDatabase();

http.createServer(async (req, res) => {
  const origin = req.headers.origin || '';
  const headers = corsHeaders(origin);
  if (req.method === 'OPTIONS') { res.writeHead(204, headers); return res.end(); }
  if (origin && !headers['Access-Control-Allow-Origin']) return send(res, 403, { message: 'Origin not allowed' }, headers);
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  try {
    if (req.method === 'GET' && url.pathname === '/health') return send(res, 200, { status: 'ok', service: 'parapente-angola-api' }, headers);
    if (req.method === 'POST' && url.pathname === '/auth/signup') return await signUp(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/auth/signup/verify') return await verifySignUp(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/auth/token') return await signIn(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/auth/refresh') return await refresh(req, res, headers);
    if (req.method === 'GET' && url.pathname === '/auth/user') return await currentUser(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/auth/recover') return await recoverPassword(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/auth/password') return await changePassword(req, res, headers);
    if (req.method === 'POST' && url.pathname === '/internal/import') return await importRows(req, res, headers);
    if (url.pathname.startsWith('/rest/v1/')) return await proxyRest(req, res, url, headers);
    return send(res, 404, { message: 'Not found' }, headers);
  } catch (error) {
    console.error(error);
    return send(res, error.status || 500, { message: error.status ? error.message : 'Internal server error' }, headers);
  }
}).listen(port, '0.0.0.0', () => console.log(`Parapente Angola API listening on ${port}`));

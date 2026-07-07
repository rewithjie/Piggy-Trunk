import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  throw new Error('Environment variables SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.');
}

const defaultHeaders = {
  'Content-Type': 'application/json',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...defaultHeaders,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization,apikey,Content-Type',
    },
  });
}

function optionsResponse() {
  return new Response(null, {
    status: 204,
    headers: {
      ...defaultHeaders,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization,apikey,Content-Type',
    },
  });
}

function generateTemporaryPassword(length = 14) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+';
  let password = '';
  for (let i = 0; i < length; i += 1) {
    const index = Math.floor(Math.random() * alphabet.length);
    password += alphabet[index];
  }
  return password;
}

async function fetchJson(url: string, options: RequestInit) {
  const response = await fetch(url, options);
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  return { response, body };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return optionsResponse();
  }

  if (req.method !== 'POST') {
    return jsonResponse({ success: false, message: 'Method not allowed.' }, 405);
  }

  const authorization = req.headers.get('authorization') || '';
  const token = authorization.replace(/^Bearer\s+/i, '');
  if (!token) {
    return jsonResponse({ success: false, message: 'Missing authorization token.' }, 401);
  }

  const { response: authUserResponse, body: authUserBody } = await fetchJson(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: ANON_KEY,
    },
  });

  if (!authUserResponse.ok || !authUserBody || typeof authUserBody.email !== 'string') {
    return jsonResponse({ success: false, message: 'Unable to verify admin session.' }, 401);
  }

  const adminEmail = authUserBody.email as string;
  const adminQuery = [`select=user_id,role`, `email=eq.${encodeURIComponent(adminEmail)}`, 'role=eq.admin'].join('&');
  const { response: adminResponse, body: adminBody } = await fetchJson(`${SUPABASE_URL}/rest/v1/app_users?${adminQuery}`, {
    headers: {
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      apikey: SERVICE_ROLE_KEY,
      Accept: 'application/json',
    },
  });

  if (!adminResponse.ok || !Array.isArray(adminBody) || adminBody.length === 0) {
    return jsonResponse({ success: false, message: 'Only admin users can create raiser accounts.' }, 403);
  }

  const adminRow = adminBody[0] as { user_id: number; role: string };
  const requestBody = await req.json().catch(() => null);
  if (!requestBody || typeof requestBody !== 'object') {
    return jsonResponse({ success: false, message: 'Invalid request body.' }, 400);
  }

  const name = (requestBody as Record<string, unknown>).name as string;
  let email = (requestBody as Record<string, unknown>).email as string | undefined;
  const phone = (requestBody as Record<string, unknown>).phone as string;
  const address = (requestBody as Record<string, unknown>).address as string;
  const lifecycleStage = (requestBody as Record<string, unknown>).lifecycle_stage as string;
  const status = (requestBody as Record<string, unknown>).status as string;

  if (!name || !phone || !address) {
    return jsonResponse({ success: false, message: 'Name, phone, and address are required.' }, 400);
  }

  function generateLocalPart(value: string): string {
    const normalized = value
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '.')
      .replace(/(^\.|\.$)/g, '');

    const suffix = Math.random().toString(36).substring(2, 8);
    const base = normalized || 'raiser';
    return `${base}.${suffix}`;
  }

  if (!email || email.trim() === '') {
    email = `${generateLocalPart(name)}@hograiser.piggytrunk.com`;
  }

  const temporaryPassword = generateTemporaryPassword();

  const { response: createUserResponse, body: createUserBody } = await fetchJson(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      apikey: SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password: temporaryPassword,
      email_confirm: true,
      user_metadata: {
        role: 'hog_raiser',
        created_by: adminRow.user_id,
      },
    }),
  });

  if (!createUserResponse.ok || !createUserBody || typeof createUserBody.id !== 'string') {
    const message = createUserBody?.message || 'Unable to create Supabase auth user.';
    return jsonResponse({ success: false, message }, 500);
  }

  const supabaseUserId = createUserBody.id as string;
  let createdAppUserId: number | null = null;

  try {
    const { response: appUserResponse, body: appUserBody } = await fetchJson(`${SUPABASE_URL}/rest/v1/app_users?prefer=return=representation`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        apikey: SERVICE_ROLE_KEY,
        'Content-Type': 'application/json',
        Prefer: 'return=representation',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        name,
        email,
        role: 'hog_raiser',
        status: 'active',
        created_by: adminRow.user_id,
        supabase_user_id: supabaseUserId,
      }),
    });

    if (!appUserResponse.ok || !Array.isArray(appUserBody) || appUserBody.length === 0) {
      const message = appUserBody?.message || 'Unable to create app_users record.';
      throw new Error(String(message));
    }

    createdAppUserId = appUserBody[0].user_id as number;

    const { response: hogResponse, body: hogBody } = await fetchJson(`${SUPABASE_URL}/rest/v1/hog_raisers?prefer=return=representation`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        apikey: SERVICE_ROLE_KEY,
        'Content-Type': 'application/json',
        Prefer: 'return=representation',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        address,
        contact_number: phone,
        account_status: status.toLowerCase() === 'active' ? 'active' : status,
        user_id: createdAppUserId,
        lifecycle_stage: lifecycleStage,
      }),
    });

    if (!hogResponse.ok || !Array.isArray(hogBody) || hogBody.length === 0) {
      const message = hogBody?.message || 'Unable to create hog_raisers record.';
      throw new Error(String(message));
    }

    return jsonResponse({
      success: true,
      data: {
        temporary_password: temporaryPassword,
        auth_user: createUserBody,
        app_user: appUserBody[0],
        hog_raiser: hogBody[0],
      },
    });
  } catch (error) {
    if (supabaseUserId) {
      await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${supabaseUserId}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          apikey: SERVICE_ROLE_KEY,
        },
      }).catch(() => undefined);
    }
    if (createdAppUserId) {
      await fetch(`${SUPABASE_URL}/rest/v1/app_users?user_id=eq.${createdAppUserId}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          apikey: SERVICE_ROLE_KEY,
        },
      }).catch(() => undefined);
    }

    return jsonResponse({ success: false, message: String(error) }, 500);
  }
});

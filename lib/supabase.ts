import { createClient } from '@supabase/supabase-js';

// Retrieve environment variables with strict fallbacks
const getSupabaseUrl = (): string => {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url || url.includes('placeholder')) {
    return 'https://local.waypoint.internal';
  }
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
      return 'https://local.waypoint.internal';
    }
    return url;
  } catch {
    return 'https://local.waypoint.internal';
  }
};

const getSupabaseAnonKey = (): string => {
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!key || key.includes('placeholder')) {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndheXBvaW50Iiwicm9sZSI6ImFub24ifQ.placeholder';
  }
  // Enforce zero client-side service-role key leakage
  if (key.toLowerCase().includes('service_role')) {
    console.error('[SECURITY WARNING] Supabase service_role key detected in client bundle. Defaulting to anon key restriction.');
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndheXBvaW50Iiwicm9sZSI6ImFub24ifQ.placeholder';
  }
  return key;
};

const supabaseUrl = getSupabaseUrl();
const supabaseAnonKey = getSupabaseAnonKey();

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
});


-- =====================================================================
-- WayPoint Production PostgreSQL Schema & Row Level Security (RLS) Policies
-- Task 3.2: Row Level Security (RLS) Policies & Schema Hardening
-- =====================================================================

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    traveler_name TEXT,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Trips Table (Document-style JSONB & normalized relational support)
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    destination TEXT NOT NULL,
    traveler_name TEXT NOT NULL,
    currency_code TEXT DEFAULT 'USD' NOT NULL,
    days JSONB NOT NULL DEFAULT '[]'::jsonb,
    selected_day_index INT DEFAULT 0 NOT NULL,
    version INT DEFAULT 1 NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Itinerary Items Table (Relational Child of Trips)
CREATE TABLE IF NOT EXISTS public.itinerary_items (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
    day_index INT DEFAULT 0 NOT NULL,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    estimated_cost NUMERIC DEFAULT 0 NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Bookings / Passes Table (Relational Child of Trips)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    provider TEXT NOT NULL,
    confirmation_code TEXT NOT NULL,
    type TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    seat_or_room TEXT,
    barcode_data TEXT,
    notes TEXT,
    location TEXT,
    cost NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Expenses Table (Relational Child of Trips)
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC NOT NULL,
    currency_code TEXT DEFAULT 'USD' NOT NULL,
    category TEXT NOT NULL,
    merchant TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Sync Revisions Table
CREATE TABLE IF NOT EXISTS public.sync_revisions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE NOT NULL,
    mutation_reason TEXT NOT NULL,
    version INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- Performance & Composite Indexes
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_trips_user_id ON public.trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_user_id_updated_at ON public.trips(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_itinerary_items_trip_day ON public.itinerary_items(trip_id, day_index);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip_id ON public.bookings(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user_trip ON public.expenses(user_id, trip_id);
CREATE INDEX IF NOT EXISTS idx_sync_revisions_user_trip ON public.sync_revisions(user_id, trip_id);

-- =====================================================================
-- Row Level Security (RLS) Activation across all 6 Tables
-- =====================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_revisions ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------
-- RLS Policies for Profiles
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
CREATE POLICY "Users can delete own profile" ON public.profiles FOR DELETE USING (auth.uid() = id);

-- ---------------------------------------------------------------------
-- RLS Policies for Trips
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own trips" ON public.trips;
CREATE POLICY "Users can view own trips" ON public.trips FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own trips" ON public.trips;
CREATE POLICY "Users can insert own trips" ON public.trips FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own trips" ON public.trips;
CREATE POLICY "Users can update own trips" ON public.trips FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own trips" ON public.trips;
CREATE POLICY "Users can delete own trips" ON public.trips FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- RLS Policies for Itinerary Items
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own itinerary_items" ON public.itinerary_items;
CREATE POLICY "Users can view own itinerary_items" ON public.itinerary_items FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own itinerary_items" ON public.itinerary_items;
CREATE POLICY "Users can insert own itinerary_items" ON public.itinerary_items FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own itinerary_items" ON public.itinerary_items;
CREATE POLICY "Users can update own itinerary_items" ON public.itinerary_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own itinerary_items" ON public.itinerary_items;
CREATE POLICY "Users can delete own itinerary_items" ON public.itinerary_items FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- RLS Policies for Bookings
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
CREATE POLICY "Users can view own bookings" ON public.bookings FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own bookings" ON public.bookings;
CREATE POLICY "Users can insert own bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;
CREATE POLICY "Users can update own bookings" ON public.bookings FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own bookings" ON public.bookings;
CREATE POLICY "Users can delete own bookings" ON public.bookings FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- RLS Policies for Expenses
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own expenses" ON public.expenses;
CREATE POLICY "Users can view own expenses" ON public.expenses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own expenses" ON public.expenses;
CREATE POLICY "Users can insert own expenses" ON public.expenses FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own expenses" ON public.expenses;
CREATE POLICY "Users can update own expenses" ON public.expenses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own expenses" ON public.expenses;
CREATE POLICY "Users can delete own expenses" ON public.expenses FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- RLS Policies for Sync Revisions
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own sync_revisions" ON public.sync_revisions;
CREATE POLICY "Users can view own sync_revisions" ON public.sync_revisions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sync_revisions" ON public.sync_revisions;
CREATE POLICY "Users can insert own sync_revisions" ON public.sync_revisions FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sync_revisions" ON public.sync_revisions;
CREATE POLICY "Users can update own sync_revisions" ON public.sync_revisions FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own sync_revisions" ON public.sync_revisions;
CREATE POLICY "Users can delete own sync_revisions" ON public.sync_revisions FOR DELETE USING (auth.uid() = user_id);

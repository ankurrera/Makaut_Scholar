-- 1. Create the profiles table
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  name text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (id)
);

-- 2. Enable Row Level Security (RLS)
-- This ensures users can only access data they are allowed to see
alter table public.profiles enable row level security;

-- 3. Create Policies

-- Policy A: Allow users to insert their OWN profile
-- This is required for your signUp function in auth_service.dart to work
create policy "Users can insert their own profile"
on public.profiles for insert
to authenticated
with check ( auth.uid() = id );

-- Policy B: Allow users to see their OWN profile
-- (You can change this later if you want profiles to be public)
create policy "Users can view their own profile"
on public.profiles for select
to authenticated
using ( auth.uid() = id );

-- Policy C: Allow users to update their OWN profile
create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using ( auth.uid() = id );
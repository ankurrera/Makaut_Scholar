-- Create PYQ Table
create table if not exists pyq (
  id uuid default gen_random_uuid() primary key,
  department text not null,
  semester int not null,
  subject text not null,
  year text not null, -- e.g., "2022-23"
  file_url text not null,
  uploaded_at timestamptz default now()
);

-- Enable RLS
alter table pyq enable row level security;

-- FIX: DROP old restrictive policies if they exist (to avoid constraints)
drop policy if exists "Enable all for authenticated users" on pyq;
drop policy if exists "Enable read access for all" on pyq;

-- FIX: ALLOW ALL access (Insert, Update, Delete, Select) for everyone (anon + authenticated)
-- This fixes "new row violates row-level security policy"
create policy "Allow Full Access" on pyq
  for all using (true) with check (true);


-- STORAGE BUCKET
insert into storage.buckets (id, name, public) 
values ('pyqs_pdf', 'pyqs_pdf', true)
on conflict (id) do nothing;

-- STORAGE POLICIES
-- Drop potentially conflicting old policies first
drop policy if exists "Auth Upload" on storage.objects;
drop policy if exists "Auth Delete" on storage.objects;

-- Create Permissive Policies
create policy "PYQ Public Select" on storage.objects
  for select using ( bucket_id = 'pyqs_pdf' );

create policy "PYQ Public Upload" on storage.objects
  for insert with check ( bucket_id = 'pyqs_pdf' );

create policy "PYQ Public Delete" on storage.objects
  for delete using ( bucket_id = 'pyqs_pdf' );

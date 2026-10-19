-- Store Drive OAuth tokens
create table drive_tokens (
  user_id uuid references auth.users primary key,
  access_token text,
  refresh_token text, 
  expiry timestamptz,
  scope text
);

-- Ensure RLS is enabled and users can only access their own tokens
alter table drive_tokens enable row level security;
create policy "Users can view own drive_tokens" on drive_tokens for select using (auth.uid() = user_id);
create policy "Users can modify own drive_tokens" on drive_tokens for all using (auth.uid() = user_id);

-- Spaces (Folders in Drive)
create table spaces (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null, -- Used as Drive folder name
  drive_folder_id text not null, -- ID of MemInbox/{name} folder
  icon text default 'folder',
  position int default 0,
  created_at timestamptz default now(),
  unique(user_id, name)
);

alter table spaces enable row level security;
create policy "Users can view own spaces" on spaces for select using (auth.uid() = user_id);
create policy "Users can modify own spaces" on spaces for all using (auth.uid() = user_id);

-- Files metadata
create table files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  drive_file_id text not null unique,
  space_id uuid references spaces(id) on delete set null,
  drive_parent_id text not null, -- folder it lives in
  mime_type text,
  original_name text not null,
  size_bytes bigint,
  thumbnail_link text, -- from Drive API
  web_content_link text, -- direct download
  created_at timestamptz default now(),
  fts tsvector generated always as (to_tsvector('english', original_name)) stored
);

alter table files enable row level security;
create policy "Users can view own files" on files for select using (auth.uid() = user_id);
create policy "Users can modify own files" on files for all using (auth.uid() = user_id);

create index files_user_fts_idx on files using gin(fts);
create index files_space_idx on files(space_id);

-- Inbox items tracking
create table inbox_items (
  file_id uuid references files(id) on delete cascade primary key,
  user_id uuid references auth.users not null,
  is_sorted boolean default false,
  added_at timestamptz default now()
);

alter table inbox_items enable row level security;
create policy "Users can view own inbox_items" on inbox_items for select using (auth.uid() = user_id);
create policy "Users can modify own inbox_items" on inbox_items for all using (auth.uid() = user_id);

create index inbox_items_user_unsorted_idx on inbox_items(user_id, is_sorted) where is_sorted = false;

-- Rate limiting table for Edge Functions (50 uploads / 500MB per day per user)
create table user_usage_stats (
  user_id uuid references auth.users not null,
  date date not null default current_date,
  upload_count int default 0,
  bytes_uploaded bigint default 0,
  primary key (user_id, date)
);

alter table user_usage_stats enable row level security;
create policy "Users can view own stats" on user_usage_stats for select using (auth.uid() = user_id);

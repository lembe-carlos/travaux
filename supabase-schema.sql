-- =============================================================================
-- SAHEL BTP — Schéma Supabase / PostgreSQL
-- À exécuter intégralement dans l'éditeur SQL de votre projet Supabase
-- (Project → SQL Editor → New query → coller ce fichier → Run)
-- =============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Utilisateurs
-- ---------------------------------------------------------------------------
create table if not exists users (
  id uuid primary key,
  name text not null,
  email text unique not null,
  password text, -- utilisé uniquement en mode local (sans Supabase Auth) ; laissé vide en mode connecté, le mot de passe étant géré par Supabase Auth
  role text not null default 'user',
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- Migration : si vous aviez déjà exécuté une version précédente de ce script
-- (où "password" était obligatoire), cette ligne corrige la table existante
-- pour permettre l'authentification réelle via Supabase Auth. Sans danger à
-- exécuter même si la colonne est déjà nullable.
alter table users alter column password drop not null;

-- Permet à un visiteur non encore connecté de savoir si un compte existe déjà
-- (pour afficher l'écran de connexion plutôt que l'écran de création du tout
-- premier compte), sans lui laisser lire le contenu de la table "users".
create or replace function public.has_any_user()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists(select 1 from users);
$$;
grant execute on function public.has_any_user() to anon, authenticated;

-- =============================================================================
-- Stockage des photos de matériaux (Supabase Storage)
-- =============================================================================
insert into storage.buckets (id, name, public)
values ('materials', 'materials', true)
on conflict (id) do nothing;

drop policy if exists "materials_photos_public_read" on storage.objects;
create policy "materials_photos_public_read" on storage.objects
  for select using (bucket_id = 'materials');

drop policy if exists "materials_photos_authenticated_write" on storage.objects;
create policy "materials_photos_authenticated_write" on storage.objects
  for insert with check (bucket_id = 'materials' and auth.uid() is not null);

drop policy if exists "materials_photos_authenticated_update" on storage.objects;
create policy "materials_photos_authenticated_update" on storage.objects
  for update using (bucket_id = 'materials' and auth.uid() is not null);

drop policy if exists "materials_photos_authenticated_delete" on storage.objects;
create policy "materials_photos_authenticated_delete" on storage.objects
  for delete using (bucket_id = 'materials' and auth.uid() is not null);

-- ---------------------------------------------------------------------------
-- Référentiel matériaux
-- ---------------------------------------------------------------------------
create table if not exists categories (
  id uuid primary key,
  name text not null,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists warehouses (
  id uuid primary key,
  name text not null,
  address text,
  manager text,
  phone text,
  capacity numeric,
  status text default 'actif',
  parent_warehouse_id uuid references warehouses(id),
  created_at timestamptz default now(),
  updated_at timestamptz
);
alter table warehouses add column if not exists parent_warehouse_id uuid references warehouses(id);

create table if not exists suppliers (
  id uuid primary key,
  company text not null,
  contact text,
  phone text,
  whatsapp text,
  email text,
  address text,
  city text,
  country text default 'Cameroun',
  tax_id text,
  payment_terms text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists materials (
  id uuid primary key,
  reference text not null,
  name text not null,
  category_id uuid references categories(id),
  subcategory text,
  description text,
  unit text not null,
  purchase_price numeric default 0,
  sale_price numeric default 0,
  min_stock numeric default 0,
  max_stock numeric,
  supplier_id uuid references suppliers(id),
  location text,
  photo_url text,
  status text default 'actif',
  created_at timestamptz default now(),
  updated_at timestamptz
);
-- Migration : ajoute les colonnes si la table existait déjà avec l'ancien schéma
alter table materials add column if not exists subcategory text;
alter table materials add column if not exists description text;
alter table materials add column if not exists location text;
alter table materials add column if not exists photo_url text;

create table if not exists unit_conversions (
  id uuid primary key,
  from_unit text not null,
  to_unit text not null,
  factor numeric not null,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists loss_declarations (
  id uuid primary key,
  material_id uuid references materials(id),
  warehouse_id uuid references warehouses(id),
  project_id uuid references projects(id),
  quantity numeric not null,
  reason text not null,
  comment text,
  declared_by text,
  status text default 'en_attente',
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Stock
-- ---------------------------------------------------------------------------
create table if not exists stock (
  id uuid primary key,
  material_id uuid references materials(id) on delete cascade,
  warehouse_id uuid references warehouses(id) on delete cascade,
  quantity numeric not null default 0,
  unique (material_id, warehouse_id)
);

create table if not exists stock_movements (
  id uuid primary key,
  number text,
  type text not null,
  direction text not null check (direction in ('in','out')),
  material_id uuid references materials(id),
  material_name text,
  unit text,
  warehouse_id uuid references warehouses(id),
  destination_warehouse_id uuid references warehouses(id),
  project_id uuid,
  quantity numeric not null,
  reference text,
  reason text,
  comment text,
  "user" text,
  date timestamptz default now(),
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists inventories (
  id uuid primary key,
  warehouse_id uuid references warehouses(id),
  warehouse_name text,
  "user" text,
  lines jsonb,
  gaps_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Chantiers
-- ---------------------------------------------------------------------------
create table if not exists projects (
  id uuid primary key,
  code text not null,
  name text not null,
  client text,
  location text,
  manager text,
  start_date date,
  end_date date,
  budget numeric,
  status text default 'Planifié',
  description text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists project_material_requests (
  id uuid primary key,
  project_id uuid references projects(id) on delete cascade,
  requested_by text,
  status text default 'en_attente',
  bon_sortie_number text,
  prepared_warehouse_id uuid references warehouses(id),
  received_at timestamptz,
  received_by text,
  lines jsonb not null default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz
);
alter table project_material_requests add column if not exists bon_sortie_number text;
alter table project_material_requests add column if not exists prepared_warehouse_id uuid references warehouses(id);
alter table project_material_requests add column if not exists received_at timestamptz;
alter table project_material_requests add column if not exists received_by text;

create table if not exists project_material_consumptions (
  id uuid primary key,
  project_id uuid references projects(id) on delete cascade,
  material_id uuid references materials(id),
  quantity numeric not null default 0,
  comment text,
  "user" text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists project_material_allocations (
  id uuid primary key,
  project_id uuid references projects(id) on delete cascade,
  material_id uuid references materials(id),
  quantity_allocated numeric default 0,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Achats
-- ---------------------------------------------------------------------------
create table if not exists purchase_requests (
  id uuid primary key,
  requested_by text,
  status text default 'en_attente',
  lines jsonb not null default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists purchase_orders (
  id uuid primary key,
  number text,
  supplier_id uuid references suppliers(id),
  status text default 'en_attente',
  requested_by text,
  source_request_id uuid references purchase_requests(id),
  lines jsonb default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists goods_receipts (
  id uuid primary key,
  purchase_order_id uuid references purchase_orders(id),
  supplier_id uuid references suppliers(id),
  delivery_number text,
  warehouse_id uuid references warehouses(id),
  items jsonb default '[]',
  received_by text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists invoices (
  id uuid primary key,
  number text,
  supplier_id uuid references suppliers(id),
  purchase_order_id uuid references purchase_orders(id),
  amount numeric not null default 0,
  due_date date,
  status text default 'en_attente',
  paid_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Ventes
-- ---------------------------------------------------------------------------
create table if not exists customers (
  id uuid primary key,
  name text not null,
  phone text,
  email text,
  address text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists quotes (
  id uuid primary key,
  number text,
  customer_id uuid references customers(id),
  status text default 'brouillon',
  lines jsonb default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists sales_orders (
  id uuid primary key,
  number text,
  customer_id uuid references customers(id),
  quote_id uuid references quotes(id),
  status text default 'en_attente',
  lines jsonb default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists sales_invoices (
  id uuid primary key,
  number text,
  customer_id uuid references customers(id),
  sales_order_id uuid references sales_orders(id),
  amount numeric not null default 0,
  status text default 'en_attente',
  paid_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Notifications et journalisation
-- ---------------------------------------------------------------------------
create table if not exists notifications (
  id uuid primary key,
  category text,
  level text,
  material_id uuid references materials(id),
  message text not null,
  read boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz
);

create table if not exists activity_logs (
  id uuid primary key,
  "user" text,
  "table" text,
  action text,
  label text,
  created_at timestamptz default now()
);

-- =============================================================================
-- Sécurité (Row Level Security)
-- =============================================================================
-- Cette application utilise désormais Supabase Auth (vrais comptes, mots de
-- passe chiffrés côté serveur, réinitialisation par e-mail). Les règles
-- ci-dessous exigent une session valide (utilisateur connecté) pour toute
-- lecture ou écriture : une personne qui ne s'est pas authentifiée via
-- Supabase Auth ne peut rien lire ni modifier, même en connaissant l'URL et
-- la clé publique du projet.
--
-- Ce niveau de sécurité convient à une équipe interne où tous les comptes
-- connectés sont de confiance (n'importe quel utilisateur connecté peut
-- lire/écrire dans toutes les tables ; le contrôle plus fin par rôle — qui a
-- le droit de faire quoi — reste géré côté application, dans la table
-- "users" et permissions.js). Pour une sécurité encore plus poussée par la
-- suite (policies différentes par rôle directement dans PostgreSQL), c'est
-- une évolution possible.

alter table users enable row level security;
alter table categories enable row level security;
alter table warehouses enable row level security;
alter table suppliers enable row level security;
alter table materials enable row level security;
alter table unit_conversions enable row level security;
alter table loss_declarations enable row level security;
alter table stock enable row level security;
alter table stock_movements enable row level security;
alter table inventories enable row level security;
alter table projects enable row level security;
alter table project_material_requests enable row level security;
alter table project_material_allocations enable row level security;
alter table project_material_consumptions enable row level security;
alter table purchase_requests enable row level security;
alter table purchase_orders enable row level security;
alter table goods_receipts enable row level security;
alter table invoices enable row level security;
alter table customers enable row level security;
alter table quotes enable row level security;
alter table sales_orders enable row level security;
alter table sales_invoices enable row level security;
alter table notifications enable row level security;
alter table activity_logs enable row level security;

-- Politique : autorise toutes les opérations, mais UNIQUEMENT pour une
-- requête authentifiée (session Supabase Auth valide).
do $$
declare
  t text;
begin
  for t in select unnest(array[
    'users','categories','warehouses','suppliers','materials','unit_conversions','loss_declarations','stock',
    'stock_movements','inventories','projects','project_material_requests','project_material_allocations','project_material_consumptions',
    'purchase_requests','purchase_orders','goods_receipts','invoices',
    'customers','quotes','sales_orders','sales_invoices','notifications','activity_logs'
  ])
  loop
    execute format('drop policy if exists "allow_all_%s" on %I;', t, t);
    execute format('drop policy if exists "authenticated_only_%s" on %I;', t, t);
    execute format('create policy "authenticated_only_%s" on %I for all using (auth.uid() is not null) with check (auth.uid() is not null);', t, t);
  end loop;
end $$;

-- Cas particulier de la table "users" : chacun doit pouvoir lire son propre
-- profil même juste après son inscription (avant qu'un rôle lui soit
-- attribué), et pouvoir créer sa propre ligne de profil à l'inscription.
-- La policy générique ci-dessus couvre déjà ce besoin (auth.uid() is not
-- null suffit puisque tout compte inscrit est authentifié) — aucune policy
-- supplémentaire n'est nécessaire ici.

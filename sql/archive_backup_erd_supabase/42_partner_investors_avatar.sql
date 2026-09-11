-- Add avatar_url to partner_investors and cashiers for avatar sync across admin web and mobile
alter table if exists public.partner_investors
  add column if not exists avatar_url text;

alter table if exists public.cashiers
  add column if not exists avatar_url text;

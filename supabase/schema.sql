-- Barbearia Oliveira: estrutura do banco no Supabase.
-- Cole tudo no SQL Editor do Supabase e clique em Run. Pode rodar mais de uma vez.
--
-- Se mudar horários de funcionamento, serviços ou preços no index.html,
-- ajuste também a função criar_agendamento mais abaixo.

create table if not exists public.admins (email text primary key);

create table if not exists public.bookings (
  id         text primary key,
  date       date not null,
  start_min  int  not null,
  dur        int  not null default 30,
  svc        text not null,
  svc_name   text not null,
  price      numeric(8,2) not null,
  name       text not null,
  ctype      text not null default 'whatsapp',
  contact    text not null,
  status     text not null default 'agendado' check (status in ('agendado','concluido','cancelado')),
  created    bigint not null
);

create table if not exists public.slots (
  key        text primary key,
  date       date not null,
  booking_id text
);

create table if not exists public.blocks (
  key        text primary key,
  date       date not null,
  start_min  int  not null
);

create index if not exists bookings_date_idx on public.bookings (date);
create index if not exists slots_date_idx    on public.slots (date);
create index if not exists blocks_date_idx   on public.blocks (date);

alter table public.admins   enable row level security;
alter table public.bookings enable row level security;
alter table public.slots    enable row level security;
alter table public.blocks   enable row level security;

-- Quem é o barbeiro: e-mails cadastrados na tabela admins.
create or replace function public.sou_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.sou_admin() from public;
grant execute on function public.sou_admin() to anon, authenticated;

-- Permissões das tabelas
revoke all on public.bookings from anon;
revoke all on public.admins   from anon, authenticated;
grant select on public.slots, public.blocks to anon, authenticated;
grant select, insert, update, delete on public.slots, public.blocks, public.bookings to authenticated;

-- Clientes só enxergam quais horários estão ocupados (sem nome nem contato).
drop policy if exists slots_leitura on public.slots;
create policy slots_leitura on public.slots for select to anon, authenticated using (true);
drop policy if exists slots_admin on public.slots;
create policy slots_admin on public.slots for all to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

drop policy if exists blocks_leitura on public.blocks;
create policy blocks_leitura on public.blocks for select to anon, authenticated using (true);
drop policy if exists blocks_admin on public.blocks;
create policy blocks_admin on public.blocks for all to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

-- Só o barbeiro lê e altera os agendamentos (nomes, contatos, valores).
drop policy if exists bookings_admin on public.bookings;
create policy bookings_admin on public.bookings for all to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

-- O cliente agenda por esta função. Ela confere tudo no servidor e reserva o
-- horário de uma vez, então dois clientes nunca ficam com o mesmo horário.
create or replace function public.criar_agendamento(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_agora int := extract(hour from (now() at time zone 'America/Sao_Paulo'))::int * 60
               + extract(minute from (now() at time zone 'America/Sao_Paulo'))::int;
  v_date date;
  v_start int;
  v_svc text;
  v_svc_name text;
  v_price numeric;
  v_nome text;
  v_contact text;
  v_dow int;
  v_key text;
  v_id text;
begin
  v_date    := (p ->> 'date')::date;
  v_start   := (p ->> 'start')::int;
  v_svc     := p ->> 'svc';
  v_nome    := btrim(regexp_replace(coalesce(p ->> 'name', ''), '\s+', ' ', 'g'));
  v_contact := regexp_replace(coalesce(p ->> 'contact', ''), '\D', '', 'g');

  if v_date is null or v_date < v_hoje or v_date > v_hoje + 29 then
    raise exception 'data_invalida';
  end if;

  -- Horários de funcionamento (minutos desde 00:00; 780 = 13:00, 1050 = 17:30 é o último início)
  v_dow := extract(dow from v_date)::int;
  if v_start is null or v_start % 30 <> 0 or not (
       (v_dow in (1, 3, 5) and v_start between 780 and 1050)
    or (v_dow in (2, 4)    and v_start between 870 and 1050)
    or (v_dow in (0, 6)    and (v_start between 420 and 690 or v_start between 780 and 1050))
  ) then
    raise exception 'horario_invalido';
  end if;
  if v_date = v_hoje and v_start <= v_agora then
    raise exception 'horario_invalido';
  end if;

  -- Serviços e preços
  case v_svc
    when 'corte'       then v_svc_name := 'Corte';         v_price := 20;
    when 'luzes'       then v_svc_name := 'Luzes';         v_price := 60;
    when 'corte-luzes' then v_svc_name := 'Corte + luzes'; v_price := 80;
    when 'nevou'       then v_svc_name := 'Nevou';         v_price := 70;
    when 'corte-nevou' then v_svc_name := 'Corte + nevou'; v_price := 90;
    else raise exception 'servico_invalido';
  end case;

  if char_length(v_nome) < 2 or char_length(v_nome) > 60 then
    raise exception 'nome_invalido';
  end if;
  if char_length(v_contact) not in (10, 11) then
    raise exception 'contato_invalido';
  end if;

  v_key := to_char(v_date, 'YYYY-MM-DD') || '_' || lpad((v_start / 60)::text, 2, '0') || lpad((v_start % 60)::text, 2, '0');

  if exists (select 1 from public.blocks where key = v_key) then
    raise exception 'horario_ocupado';
  end if;

  v_id := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));

  begin
    insert into public.slots (key, date, booking_id) values (v_key, v_date, v_id);
  exception when unique_violation then
    raise exception 'horario_ocupado';
  end;

  insert into public.bookings (id, date, start_min, dur, svc, svc_name, price, name, ctype, contact, status, created)
  values (v_id, v_date, v_start, 30, v_svc, v_svc_name, v_price, v_nome, 'whatsapp', v_contact, 'agendado',
          (extract(epoch from clock_timestamp()) * 1000)::bigint);

  return v_id;
end;
$$;
revoke all on function public.criar_agendamento(jsonb) from public;
grant execute on function public.criar_agendamento(jsonb) to anon, authenticated;

-- Por último: cadastre o e-mail do barbeiro (troque pelo e-mail que vai usar no login).
-- insert into public.admins (email) values ('seu-email@exemplo.com') on conflict do nothing;

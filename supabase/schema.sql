-- Autor: Davi de Assis Fabricio
-- =====================================================================
-- MOUNATOR - schema do Supabase (PostgreSQL)
-- Cole este arquivo inteiro no SQL Editor do Supabase e clique em RUN.
-- Pode ser executado de novo: ele recria tudo do zero (apaga os dados do app).
-- =====================================================================

-- ---------- limpeza ----------
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.get_ranking(int);
drop function if exists public.complete_mission(uuid, boolean);
drop function if exists public.start_mission(uuid);
drop table if exists public.user_achievements, public.user_missions,
  public.achievements, public.missions, public.questions,
  public.characters, public.profiles cascade;

-- ---------- tabelas ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 24),
  score       integer not null default 0 check (score >= 0),
  created_at  timestamptz not null default now()
);

create table public.missions (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  description   text not null,
  category      text not null,
  difficulty    text not null check (difficulty in ('facil', 'medio', 'dificil')),
  points        integer not null check (points > 0),
  instructions  text not null default '',
  icon          text not null default '🐭',
  max_questions integer not null default 10 check (max_questions between 3 and 30),
  featured      boolean not null default false,
  sort_order    integer not null default 0
);

-- Personagens que o rato conhece. "traits" são as características verdadeiras de cada um.
create table public.characters (
  id        uuid primary key default gen_random_uuid(),
  category  text not null,
  name      text not null,
  emoji     text not null,
  traits    text[] not null default '{}'
);

-- Perguntas do rato. Cada pergunta testa uma "trait".
create table public.questions (
  id             uuid primary key default gen_random_uuid(),
  category       text not null,
  trait          text not null,
  question_text  text not null
);

create table public.achievements (
  id                  uuid primary key default gen_random_uuid(),
  code                text not null unique,
  name                text not null,
  description         text not null,
  icon                text not null,
  condition_type      text not null check (condition_type in
                        ('missions_completed', 'distinct_days', 'score', 'stumped', 'category_completed')),
  condition_value     integer not null,
  condition_category  text
);

create table public.user_missions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles(id) on delete cascade,
  mission_id     uuid not null references public.missions(id) on delete cascade,
  status         text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  stumped        boolean not null default false,
  points_earned  integer not null default 0,
  started_at     timestamptz not null default now(),
  completed_at   timestamptz,
  unique (user_id, mission_id)   -- a mesma missão nunca pontua duas vezes para o mesmo usuário
);

create table public.user_achievements (
  user_id         uuid not null references public.profiles(id) on delete cascade,
  achievement_id  uuid not null references public.achievements(id) on delete cascade,
  unlocked_at     timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

-- ---------- perfil criado automaticamente no cadastro ----------
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nickname)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
                  split_part(new.email, '@', 1), 'Rato'), 24)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- usuários que já existiam antes deste script
insert into public.profiles (id, nickname)
select u.id, left(coalesce(nullif(trim(u.raw_user_meta_data ->> 'nickname'), ''),
                           split_part(u.email, '@', 1), 'Rato'), 24)
from auth.users u
on conflict (id) do nothing;

-- ---------- segurança (RLS + privilégios) ----------
alter table public.profiles          enable row level security;
alter table public.missions          enable row level security;
alter table public.characters        enable row level security;
alter table public.questions         enable row level security;
alter table public.achievements      enable row level security;
alter table public.user_missions     enable row level security;
alter table public.user_achievements enable row level security;

-- o cliente não escreve em nada diretamente, exceto o apelido do próprio perfil
revoke all on public.profiles, public.missions, public.characters, public.questions,
  public.achievements, public.user_missions, public.user_achievements
  from anon, authenticated;

grant select on public.profiles, public.missions, public.characters, public.questions,
  public.achievements, public.user_missions, public.user_achievements to authenticated;
grant update (nickname) on public.profiles to authenticated;   -- score NÃO é editável pelo app

create policy profiles_select on public.profiles
  for select to authenticated using (true);
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy missions_select     on public.missions     for select to authenticated using (true);
create policy characters_select   on public.characters   for select to authenticated using (true);
create policy questions_select    on public.questions    for select to authenticated using (true);
create policy achievements_select on public.achievements for select to authenticated using (true);

create policy user_missions_select_own on public.user_missions
  for select to authenticated using (user_id = auth.uid());
create policy user_achievements_select_own on public.user_achievements
  for select to authenticated using (user_id = auth.uid());

-- ---------- funções (única porta de escrita da pontuação) ----------
create function public.start_mission(p_mission_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Você precisa estar logado.';
  end if;
  if not exists (select 1 from public.missions where id = p_mission_id) then
    raise exception 'Missão não encontrada.';
  end if;
  insert into public.user_missions (user_id, mission_id, status)
  values (auth.uid(), p_mission_id, 'in_progress')
  on conflict (user_id, mission_id) do nothing;
end;
$$;

create function public.complete_mission(p_mission_id uuid, p_stumped boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid     uuid := auth.uid();
  v_row     public.user_missions%rowtype;
  v_points  integer;
  v_bonus   integer := 0;
  v_total   integer;
  v_count   integer;
  v_days    integer;
  v_score   integer;
  v_stumps  integer;
  v_new     jsonb := '[]'::jsonb;
  a         record;
  v_ok      boolean;
begin
  if v_uid is null then
    raise exception 'Você precisa estar logado.';
  end if;

  select * into v_row from public.user_missions
   where user_id = v_uid and mission_id = p_mission_id
   for update;

  if not found then
    raise exception 'Inicie a missão antes de concluir.';
  end if;

  -- idempotente: concluir de novo não dá pontos
  if v_row.status = 'completed' then
    return jsonb_build_object('points', 0, 'bonus', 0, 'already_completed', true,
                              'new_achievements', '[]'::jsonb);
  end if;

  select points into v_points from public.missions where id = p_mission_id;
  if coalesce(p_stumped, false) then
    v_bonus := v_points / 2;       -- bônus de 50% por enganar o rato
  end if;
  v_total := v_points + v_bonus;

  update public.user_missions
     set status = 'completed',
         stumped = coalesce(p_stumped, false),
         points_earned = v_total,
         completed_at = now()
   where id = v_row.id;

  update public.profiles set score = score + v_total where id = v_uid;

  -- avalia as conquistas
  select count(*) into v_count from public.user_missions
   where user_id = v_uid and status = 'completed';
  select count(distinct (completed_at at time zone 'America/Sao_Paulo')::date) into v_days
    from public.user_missions where user_id = v_uid and status = 'completed';
  select count(*) into v_stumps from public.user_missions
   where user_id = v_uid and status = 'completed' and stumped;
  select score into v_score from public.profiles where id = v_uid;

  for a in
    select * from public.achievements
     where id not in (select achievement_id from public.user_achievements where user_id = v_uid)
  loop
    v_ok := case a.condition_type
      when 'missions_completed' then v_count  >= a.condition_value
      when 'distinct_days'      then v_days   >= a.condition_value
      when 'score'              then v_score  >= a.condition_value
      when 'stumped'            then v_stumps >= a.condition_value
      when 'category_completed' then (
        select count(*) from public.user_missions um
          join public.missions m on m.id = um.mission_id
         where um.user_id = v_uid and um.status = 'completed'
           and m.category = a.condition_category
      ) >= a.condition_value
      else false
    end;

    if v_ok then
      insert into public.user_achievements (user_id, achievement_id)
      values (v_uid, a.id) on conflict do nothing;
      v_new := v_new || jsonb_build_array(jsonb_build_object(
        'name', a.name, 'icon', a.icon, 'description', a.description));
    end if;
  end loop;

  return jsonb_build_object('points', v_total, 'bonus', v_bonus,
                            'already_completed', false, 'new_achievements', v_new);
end;
$$;

-- Ranking calculado no banco. Devolve o top N e também a linha do usuário logado.
create function public.get_ranking(p_limit int default 50)
returns table (rank_position bigint, user_id uuid, nickname text, score int)
language sql
security definer
set search_path = public
stable
as $$
  with ranked as (
    select row_number() over (order by p.score desc, p.created_at asc) as pos,
           p.id, p.nickname, p.score
      from public.profiles p
  )
  select r.pos, r.id, r.nickname, r.score
    from ranked r
   where r.pos <= p_limit or r.id = auth.uid()
   order by r.pos;
$$;

revoke all on function public.start_mission(uuid)            from public, anon;
revoke all on function public.complete_mission(uuid, boolean) from public, anon;
revoke all on function public.get_ranking(int)                from public, anon;
grant execute on function public.start_mission(uuid)            to authenticated;
grant execute on function public.complete_mission(uuid, boolean) to authenticated;
grant execute on function public.get_ranking(int)                to authenticated;

-- =====================================================================
-- DADOS INICIAIS
-- =====================================================================

-- ---------- missões ----------
insert into public.missions
  (title, description, category, difficulty, points, instructions, icon, max_questions, featured, sort_order)
values
('Toca dos Bichos',
 'O rato farejou uma toca cheia de bichos. Pense em um animal e tente despistar o bigodudo!',
 'Animais', 'facil', 50,
 E'Pense em um animal sem contar a ninguém.\nResponda com sinceridade às perguntas do rato.\nSe ele errar o palpite final, você ganha bônus de pontos.',
 '🐾', 6, false, 1),
('Safari do Bigode',
 'O rato foi para a savana e quer descobrir qual animal está na sua cabeça.',
 'Animais', 'medio', 100,
 E'Escolha um animal em silêncio.\nO rato terá mais perguntas que na toca.\nUse "Provavelmente" quando tiver dúvida.',
 '🦁', 9, false, 2),
('Selva Impossível',
 'Quanto mais perguntas o rato faz, mais difícil é enganá-lo. Será que você aguenta?',
 'Animais', 'dificil', 150,
 E'Pense em um animal menos óbvio.\nO rato tem muitas perguntas e até três palpites.\nEnganar o rato aqui vale um bônus enorme.',
 '🐒', 12, false, 3),

('Banquete do Queijo',
 'O rato está faminto! Pense em uma comida e veja se ele adivinha antes de comer tudo.',
 'Comidas', 'facil', 50,
 E'Pense em uma comida ou bebida simples.\nResponda se ela é doce, salgada, quente ou gelada.\nSe o rato errar, o bônus é seu.',
 '🧀', 6, true, 4),
('Cozinha do Rato Chef',
 'O rato vestiu o avental e vai investigar o seu prato favorito.',
 'Comidas', 'medio', 100,
 E'Escolha uma comida em silêncio.\nPense nos ingredientes e na forma de servir.\nUse "Não sei" quando a pergunta não fizer sentido.',
 '🍕', 9, false, 5),
('Buffet Misterioso',
 'Um buffet gigante e um rato esperto. Engane-o com uma comida difícil de descobrir.',
 'Comidas', 'dificil', 150,
 E'Pense em uma comida diferente.\nO rato fará várias perguntas seguidas.\nResponda rápido para não se entregar.',
 '🍫', 12, false, 6),

('Sótão Empoeirado',
 'O rato encontrou um sótão cheio de objetos. Pense em um e deixe que ele tente descobrir.',
 'Objetos', 'facil', 50,
 E'Pense em um objeto do dia a dia.\nResponda se ele é eletrônico, grande ou de metal.\nSe o rato errar, você ganha bônus.',
 '📦', 6, false, 7),
('Feira de Quinquilharias',
 'Tem de tudo nessa feira. O rato quer saber qual coisa você escolheu.',
 'Objetos', 'medio', 100,
 E'Escolha um objeto em silêncio.\nPense em onde ele fica e para que serve.\nSeja sincero para o jogo ser justo.',
 '🎒', 9, false, 8),
('Museu das Coisas',
 'No museu, cada objeto tem uma história. O rato vai usar todas as perguntas que puder.',
 'Objetos', 'dificil', 150,
 E'Pense em um objeto menos comum.\nO rato tem até 12 perguntas e 3 palpites.\nEnganar o rato vale bônus de 50%.',
 '🏺', 12, false, 9),

('Crachá de Rato',
 'O rato quer adivinhar a profissão que você está imaginando. Hora de bater o ponto!',
 'Profissões', 'facil', 50,
 E'Pense em uma profissão conhecida.\nResponda sobre uniforme, local de trabalho e estudo.\nSe o rato errar, o bônus é seu.',
 '👷', 6, false, 10),
('Expediente Secreto',
 'O rato virou detetive e investiga qual profissão está na sua cabeça.',
 'Profissões', 'medio', 100,
 E'Escolha uma profissão em silêncio.\nPense no dia a dia de quem trabalha nela.\nUse "Provavelmente" quando houver dúvida.',
 '🕵️', 9, false, 11),
('Concurso Supremo',
 'A prova final dos ratos: descobrir sua profissão com poucas pistas e muitas perguntas.',
 'Profissões', 'dificil', 150,
 E'Pense em uma profissão menos óbvia.\nO rato tem 12 perguntas e 3 palpites.\nSe ele desistir, você ganha o bônus máximo.',
 '🏆', 12, false, 12);

-- ---------- conquistas ----------
insert into public.achievements
  (code, name, description, icon, condition_type, condition_value, condition_category)
values
('primeiros_passos',  'Primeiros Passos',     'Conclua sua primeira missão contra o rato.',        '🐾', 'missions_completed', 1,  null),
('rato_veterano',     'Rato Veterano',        'Conclua cinco missões.',                            '🧀', 'missions_completed', 5,  null),
('rei_do_queijo',     'Rei do Queijo',        'Conclua todas as 12 missões do Mounator.',          '👑', 'missions_completed', 12, null),
('consistencia',      'Consistência',         'Conclua missões em três dias diferentes.',          '📅', 'distinct_days',      3,  null),
('enganador',         'Enganador de Ratos',   'Engane o rato pela primeira vez.',                  '🎭', 'stumped',            1,  null),
('mestre_dos_bichos', 'Mestre dos Bichos',    'Conclua as 3 missões de Animais.',                  '🦁', 'category_completed', 3,  'Animais'),
('mestre_dos_sabores','Mestre dos Sabores',   'Conclua as 3 missões de Comidas.',                  '🍕', 'category_completed', 3,  'Comidas'),
('mestre_das_coisas', 'Mestre das Coisas',    'Conclua as 3 missões de Objetos.',                  '📦', 'category_completed', 3,  'Objetos'),
('mestre_dos_oficios','Mestre dos Ofícios',   'Conclua as 3 missões de Profissões.',               '🛠️', 'category_completed', 3,  'Profissões'),
('cerebro_de_queijo', 'Cérebro de Queijo',    'Alcance 500 pontos.',                               '🧠', 'score',              500, null);

-- ---------- perguntas ----------
insert into public.questions (category, trait, question_text) values
('Animais', 'mamifero',      'É um mamífero?'),
('Animais', 'voa',           'Ele consegue voar?'),
('Animais', 'agua',          'Ele vive na água ou passa muito tempo nela?'),
('Animais', 'domestico',     'É comum ter esse bicho em casa como estimação?'),
('Animais', 'carnivoro',     'Ele come carne?'),
('Animais', 'herbivoro',     'Ele come só plantas?'),
('Animais', 'grande',        'Ele é maior que uma pessoa adulta?'),
('Animais', 'pelos',         'O corpo dele é coberto de pelos?'),
('Animais', 'tem_patas',     'Ele tem patas ou pernas?'),
('Animais', 'africano',      'É um bicho típico da África?'),
('Animais', 'ovo',           'Ele nasce de ovo?'),
('Animais', 'penas_escamas', 'Ele tem penas ou escamas?'),
('Animais', 'inteligente',   'Ele é famoso por ser muito esperto?'),
('Animais', 'late',          'Ele costuma latir?'),
('Animais', 'ronrona',       'Ele costuma ronronar?'),
('Animais', 'tromba',        'Ele tem uma tromba?'),
('Animais', 'pescoco_longo', 'Ele tem o pescoço bem comprido?'),

('Comidas', 'doce',      'É doce?'),
('Comidas', 'salgado',   'É salgado?'),
('Comidas', 'fruta',     'É uma fruta?'),
('Comidas', 'gelado',    'Costuma ser servido gelado?'),
('Comidas', 'quente',    'Costuma ser servido quente?'),
('Comidas', 'carne',     'Pode ter carne?'),
('Comidas', 'laticinio', 'Tem leite ou queijo na receita?'),
('Comidas', 'graos',     'É feito de grãos, cereais ou massa?'),
('Comidas', 'cru',       'Dá para comer cru?'),
('Comidas', 'amarelo',   'Tem uma cor amarelada?'),
('Comidas', 'mao',       'Dá para comer com as mãos?'),
('Comidas', 'redondo',   'Costuma ter formato redondo?'),
('Comidas', 'sobremesa', 'É uma sobremesa?'),
('Comidas', 'saudavel',  'É considerado saudável?'),

('Objetos', 'eletronico', 'Precisa de bateria ou tomada?'),
('Objetos', 'bolso',      'Cabe em um bolso?'),
('Objetos', 'metal',      'Tem partes de metal?'),
('Objetos', 'rodas',      'Tem rodas?'),
('Objetos', 'musica',     'Faz música ou sons?'),
('Objetos', 'ler',        'Serve para ler ou se informar?'),
('Objetos', 'protege',    'Protege de chuva ou de sol?'),
('Objetos', 'cortar',     'Serve para cortar?'),
('Objetos', 'sentar',     'Dá para sentar nele?'),
('Objetos', 'corpo',      'É usado no corpo, como acessório?'),
('Objetos', 'grande',     'É maior que uma mochila?'),
('Objetos', 'casa',       'Costuma ficar dentro de casa?'),

('Profissões', 'emergencia', 'Atua em emergências?'),
('Profissões', 'uniforme',   'Usa uniforme no trabalho?'),
('Profissões', 'computador', 'Usa computador no dia a dia?'),
('Profissões', 'ar_livre',   'Trabalha ao ar livre?'),
('Profissões', 'viaja',      'Passa muito tempo viajando?'),
('Profissões', 'ensina',     'Ensina outras pessoas?'),
('Profissões', 'cria',       'Cria coisas (arte, comida, programas)?'),
('Profissões', 'ceu',        'Trabalha no céu ou no espaço?'),
('Profissões', 'comida',     'Trabalha com comida?'),
('Profissões', 'palco',      'Se apresenta para um público?'),
('Profissões', 'perigo',     'É uma profissão perigosa?'),
('Profissões', 'estudo',     'Exige muitos anos de estudo?'),
('Profissões', 'fogo',       'Combate incêndios?');

-- ---------- personagens ----------
insert into public.characters (category, name, emoji, traits) values
('Animais', 'Cachorro',  '🐶', '{mamifero,domestico,carnivoro,pelos,tem_patas,inteligente,late}'),
('Animais', 'Gato',      '🐱', '{mamifero,domestico,carnivoro,pelos,tem_patas,ronrona}'),
('Animais', 'Leão',      '🦁', '{mamifero,carnivoro,grande,pelos,tem_patas,africano}'),
('Animais', 'Elefante',  '🐘', '{mamifero,herbivoro,grande,tem_patas,africano,inteligente,tromba}'),
('Animais', 'Girafa',    '🦒', '{mamifero,herbivoro,grande,tem_patas,africano,pescoco_longo}'),
('Animais', 'Cobra',     '🐍', '{carnivoro,ovo,penas_escamas}'),
('Animais', 'Águia',     '🦅', '{voa,ovo,carnivoro,penas_escamas,tem_patas}'),
('Animais', 'Golfinho',  '🐬', '{mamifero,agua,carnivoro,grande,inteligente}'),
('Animais', 'Pinguim',   '🐧', '{agua,ovo,carnivoro,penas_escamas,tem_patas}'),
('Animais', 'Macaco',    '🐵', '{mamifero,pelos,tem_patas,inteligente}'),
('Animais', 'Tartaruga', '🐢', '{agua,ovo,herbivoro,tem_patas}'),
('Animais', 'Coelho',    '🐰', '{mamifero,domestico,herbivoro,pelos,tem_patas}'),

('Comidas', 'Pizza',      '🍕', '{salgado,quente,laticinio,graos,mao,redondo}'),
('Comidas', 'Sorvete',    '🍦', '{doce,gelado,laticinio,sobremesa,mao}'),
('Comidas', 'Maçã',       '🍎', '{doce,fruta,cru,mao,redondo,saudavel}'),
('Comidas', 'Banana',     '🍌', '{doce,fruta,cru,mao,amarelo,saudavel}'),
('Comidas', 'Arroz',      '🍚', '{salgado,quente,graos,saudavel}'),
('Comidas', 'Chocolate',  '🍫', '{doce,sobremesa,laticinio,mao}'),
('Comidas', 'Hambúrguer', '🍔', '{salgado,quente,carne,laticinio,graos,mao,redondo}'),
('Comidas', 'Salada',     '🥗', '{salgado,cru,saudavel}'),
('Comidas', 'Pipoca',     '🍿', '{salgado,quente,graos,amarelo,mao}'),
('Comidas', 'Queijo',     '🧀', '{salgado,laticinio,amarelo,cru,mao}'),

('Objetos', 'Celular',      '📱', '{eletronico,bolso,metal,musica,ler}'),
('Objetos', 'Cadeira',      '🪑', '{sentar,grande,casa}'),
('Objetos', 'Guarda-chuva', '☂️', '{metal,protege}'),
('Objetos', 'Livro',        '📖', '{ler,casa}'),
('Objetos', 'Bicicleta',    '🚲', '{metal,rodas,sentar,grande}'),
('Objetos', 'Geladeira',    '🧊', '{eletronico,metal,grande,casa}'),
('Objetos', 'Relógio',      '⌚', '{eletronico,bolso,metal,ler,corpo}'),
('Objetos', 'Tesoura',      '✂️', '{bolso,metal,cortar,casa}'),
('Objetos', 'Violão',       '🎸', '{musica,grande,casa}'),
('Objetos', 'Óculos',       '👓', '{bolso,protege,corpo}'),

('Profissões', 'Médico',      '🩺', '{emergencia,uniforme,computador,estudo}'),
('Profissões', 'Professor',   '📚', '{computador,ensina,palco,estudo}'),
('Profissões', 'Bombeiro',    '🚒', '{emergencia,uniforme,ar_livre,perigo,fogo}'),
('Profissões', 'Programador', '💻', '{computador,cria,estudo}'),
('Profissões', 'Cozinheiro',  '🍳', '{uniforme,cria,comida}'),
('Profissões', 'Piloto',      '✈️', '{uniforme,viaja,ceu,estudo}'),
('Profissões', 'Policial',    '🚓', '{emergencia,uniforme,ar_livre,perigo}'),
('Profissões', 'Agricultor',  '🌾', '{ar_livre,comida}'),
('Profissões', 'Músico',      '🎵', '{viaja,cria,palco}'),
('Profissões', 'Astronauta',  '🚀', '{uniforme,viaja,ceu,perigo,estudo}');

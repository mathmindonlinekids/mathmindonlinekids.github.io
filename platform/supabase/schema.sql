-- MathMind platform: database schema (Supabase / PostgreSQL 15+).
-- Run once in the Supabase SQL editor, then run skills.sql.
--
-- Roles: admin (methodist), teacher, parent, student.
-- Rules that the database itself enforces (row level security):
--   * a parent sees only their own children;
--   * a teacher sees only the students assigned to them;
--   * a student sees only their own work, never the answer keys and never a list of their mistakes;
--   * only the admin creates students, assigns teachers and changes programs;
--   * nobody can give themselves a role: roles come from invitations made by the admin.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
create type app_role as enum ('admin', 'teacher', 'parent', 'student');
create type skill_status as enum ('green', 'yellow', 'red', 'not_started');
create type assignment_kind as enum ('lesson', 'homework', 'practice', 'diagnostic');
create type lesson_status as enum ('scheduled', 'done', 'cancelled', 'no_show');
create type feedback_status as enum ('draft', 'sent');

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------
create table profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  role         app_role not null,
  display_name text not null default '',
  locale       text not null default 'ru' check (locale in ('ru', 'en')),
  phone        text,                       -- for WhatsApp / SMS reminders (parents)
  created_at   timestamptz not null default now()
);

create table students (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid unique references profiles (id) on delete set null, -- the child's own login, if any
  first_name  text not null,               -- first name only, no surname (data minimisation)
  grade       int  not null check (grade between 0 and 12),
  state       text not null,               -- 'NC', 'FL', ...
  timezone    text not null default 'America/New_York',
  legacy_code text unique,                 -- code used by the old GitHub Pages site (e.g. cnez7l)
  zoom_url    text,                        -- "Join the lesson" button
  goals       text,                        -- family goals from the questionnaire (admin/teacher only)
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

create table parent_students (
  parent_id  uuid references profiles (id) on delete cascade,
  student_id uuid references students (id) on delete cascade,
  primary key (parent_id, student_id)
);

create table teacher_students (
  teacher_id uuid references profiles (id) on delete cascade,
  student_id uuid references students (id) on delete cascade,
  primary key (teacher_id, student_id)
);

-- The admin invites people by email. When that email signs up, the trigger below
-- gives the new account its role and links it to students. Nobody can self-assign a role.
create table invitations (
  email       text primary key,
  role        app_role not null,
  display_name text not null default '',
  student_ids uuid[] not null default '{}',  -- parent: their children; teacher: their students; student: [self]
  created_at  timestamptz not null default now(),
  accepted_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Program: skills (state standards + our own skills) and each child's trajectory
-- ---------------------------------------------------------------------------
create table skills (
  id        text primary key,               -- 'NC.3.OA.7', 'MA.4.FR.1.3', 'OLY.backwards'
  framework text not null,                  -- 'NC', 'FL', 'OLY', 'CORE'
  grade     int,
  domain    text not null,                  -- 'Operations & Algebraic Thinking', ...
  title_en  text not null,
  title_ru  text not null,
  sort      int not null default 0
);

-- The child's individual program: which skills are in it, in what order,
-- plus an optional manual colour set by the admin or the teacher.
create table student_skills (
  student_id      uuid references students (id) on delete cascade,
  skill_id        text references skills (id) on delete cascade,
  position        int not null default 0,
  override_status skill_status,
  override_by     uuid references profiles (id),
  override_at     timestamptz,
  primary key (student_id, skill_id)
);

-- ---------------------------------------------------------------------------
-- Work: assignments, items, answer keys, attempts
-- ---------------------------------------------------------------------------
create table assignments (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references students (id) on delete cascade,
  kind       assignment_kind not null,
  number     int,                            -- Homework 10, Lesson 13 ...
  title      text not null,
  url        text,                           -- page that renders it (old site), until content moves in
  opens_at   timestamptz,
  due_at     timestamptz,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create table items (
  id            uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references assignments (id) on delete cascade,
  item_key      text not null,               -- id used inside the page, e.g. 'a1_0'
  day           int,
  section       text,
  label         text,                        -- short description for the teacher
  skill_id      text references skills (id),
  unique (assignment_id, item_key)
);

-- Answer keys live in their own table that students and parents cannot read at all.
create table item_keys (
  item_id uuid primary key references items (id) on delete cascade,
  answer  text not null
);

create table attempts (
  id         bigint generated always as identity primary key,
  student_id uuid not null references students (id) on delete cascade,
  item_id    uuid not null references items (id) on delete cascade,
  answer     text,
  correct    boolean not null,
  first_try  boolean,
  tries      int,
  seconds    int,
  created_at timestamptz not null default now()
);
create index attempts_student_item on attempts (student_id, item_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Lessons and feedback to parents
-- ---------------------------------------------------------------------------
create table lessons (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references students (id) on delete cascade,
  teacher_id  uuid references profiles (id),
  starts_at   timestamptz not null,
  minutes     int not null default 60,
  status      lesson_status not null default 'scheduled',
  topic       text,
  meeting_url text,                          -- overrides students.zoom_url if set
  created_at  timestamptz not null default now()
);

create table feedback (
  id          uuid primary key default gen_random_uuid(),
  lesson_id   uuid references lessons (id) on delete set null,
  student_id  uuid not null references students (id) on delete cascade,
  author_id   uuid references profiles (id),
  raw_notes   text,                          -- what the teacher dictated (teacher/admin only)
  draft       text,                          -- AI draft (teacher/admin only)
  final_text  text,                          -- what the parent receives
  locale      text not null default 'ru',
  status      feedback_status not null default 'draft',
  sent_at     timestamptz,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Access helpers (security definer, so policies don't recurse)
-- ---------------------------------------------------------------------------
create function my_role() returns app_role
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid()
$$;

create function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin' from profiles where id = auth.uid()), false)
$$;

-- Can the current user see this student? (admin, their teacher, their parent, the child)
create function can_see_student(sid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select is_admin()
      or exists (select 1 from teacher_students where teacher_id = auth.uid() and student_id = sid)
      or exists (select 1 from parent_students  where parent_id  = auth.uid() and student_id = sid)
      or exists (select 1 from students where id = sid and profile_id = auth.uid())
$$;

-- Staff = admin or this student's teacher (may see mistakes, notes, answer keys).
create function is_staff_for(sid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select is_admin()
      or exists (select 1 from teacher_students where teacher_id = auth.uid() and student_id = sid)
$$;

create function is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('admin', 'teacher') from profiles where id = auth.uid()), false)
$$;

-- ---------------------------------------------------------------------------
-- Sign-up: give the new account the role from its invitation
-- ---------------------------------------------------------------------------
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare inv invitations;
begin
  select * into inv from invitations where lower(email) = lower(new.email) and accepted_at is null;
  if not found then
    return new;            -- no invitation: the account exists but has no role and sees nothing
  end if;
  insert into profiles (id, role, display_name) values (new.id, inv.role, inv.display_name);
  if inv.role = 'parent' then
    insert into parent_students select new.id, unnest(inv.student_ids) on conflict do nothing;
  elsif inv.role = 'teacher' then
    insert into teacher_students select new.id, unnest(inv.student_ids) on conflict do nothing;
  elsif inv.role = 'student' then
    update students set profile_id = new.id where id = inv.student_ids[1];
  end if;
  update invitations set accepted_at = now() where email = inv.email;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------------------------
-- Skill map: colour of every skill in every child's program
--   green       : >= 80% correct over the last 10 tries, at least 4 tries, on 2+ different days
--   red         : < 50% correct (with at least 2 tries)
--   yellow      : anything in between (started, not yet secure)
--   not_started : no tries yet
-- A manual colour from the admin/teacher always wins.
-- ---------------------------------------------------------------------------
-- skill_map_all computes every colour (owner view, not granted to users).
create view skill_map_all as
with recent as (
  select a.student_id, i.skill_id, a.correct, a.created_at,
         row_number() over (partition by a.student_id, i.skill_id order by a.created_at desc) as rn
  from attempts a join items i on i.id = a.item_id
  where i.skill_id is not null
),
agg as (
  select student_id, skill_id,
         count(*)                                   as tries,
         avg(case when correct then 1.0 else 0 end) as pct,
         count(distinct (created_at at time zone 'America/New_York')::date) as days,
         max(created_at)                            as last_at
  from recent where rn <= 10
  group by student_id, skill_id
)
select ss.student_id, ss.skill_id, ss.position,
       s.framework, s.grade, s.domain, s.title_en, s.title_ru, s.sort,
       coalesce(agg.tries, 0) as tries,
       round(coalesce(agg.pct, 0) * 100)::int as pct,
       coalesce(agg.days, 0) as days,
       agg.last_at,
       ss.override_status,
       coalesce(ss.override_status,
         case when agg.tries is null then 'not_started'
              when agg.tries >= 4 and agg.pct >= 0.8 and agg.days >= 2 then 'green'
              when agg.tries >= 2 and agg.pct < 0.5 then 'red'
              else 'yellow' end::skill_status) as status
from student_skills ss
join skills s on s.id = ss.skill_id
left join agg on agg.student_id = ss.student_id and agg.skill_id = ss.skill_id;

-- skill_map is what staff and parents read: the same, filtered to their students.
-- Children use my_skill_map() instead, which hides red.
create view skill_map as
select * from skill_map_all m
where is_staff_for(m.student_id)
   or exists (select 1 from parent_students p where p.parent_id = auth.uid() and p.student_id = m.student_id);

-- What a child sees: red is shown as "coming soon", mistakes are never listed.
create function my_skill_map(sid uuid)
returns table (skill_id text, title_en text, title_ru text, domain text, pos int, status text)
language sql stable security definer set search_path = public as $$
  select skill_id, title_en, title_ru, domain, position,
         case status when 'green' then 'unlocked' when 'yellow' then 'in_progress' else 'locked' end
  from skill_map_all
  where student_id = sid and can_see_student(sid)
  order by position, sort
$$;

-- ---------------------------------------------------------------------------
-- Student actions (the only way a student writes data)
-- ---------------------------------------------------------------------------
-- Check one answer on the server: the key never reaches the browser.
create function submit_answer(p_item uuid, p_answer text, p_tries int default 1, p_seconds int default null)
returns boolean
language plpgsql security definer set search_path = public as $$
declare sid uuid; k text; ok boolean;
begin
  select a.student_id into sid from items i join assignments a on a.id = i.assignment_id where i.id = p_item;
  if sid is null or not exists (select 1 from students where id = sid and profile_id = auth.uid()) then
    raise exception 'not allowed';
  end if;
  select answer into k from item_keys where item_id = p_item;
  ok := k is not null and lower(regexp_replace(coalesce(p_answer, ''), '\s', '', 'g'))
                        = lower(regexp_replace(k, '\s', '', 'g'));
  insert into attempts (student_id, item_id, answer, correct, first_try, tries, seconds)
  values (sid, p_item, left(p_answer, 300), ok, p_tries <= 1, p_tries, p_seconds);
  return ok;
end $$;

-- Restore a child's saved answers for one assignment (answers only, no right/wrong).
create function my_saved_answers(p_assignment uuid)
returns table (item_key text, answer text)
language sql stable security definer set search_path = public as $$
  select distinct on (i.item_key) i.item_key, at.answer
  from attempts at join items i on i.id = at.item_id
  join assignments a on a.id = i.assignment_id
  where a.id = p_assignment and a.student_id in (select id from students where profile_id = auth.uid())
  order by i.item_key, at.created_at desc
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table profiles         enable row level security;
alter table students         enable row level security;
alter table parent_students  enable row level security;
alter table teacher_students enable row level security;
alter table invitations      enable row level security;
alter table skills           enable row level security;
alter table student_skills   enable row level security;
alter table assignments      enable row level security;
alter table items            enable row level security;
alter table item_keys        enable row level security;
alter table attempts         enable row level security;
alter table lessons          enable row level security;
alter table feedback         enable row level security;

-- profiles: everyone sees their own; staff see everyone; only admin edits roles.
create policy p_profiles_read  on profiles for select using (
  id = auth.uid() or is_admin()
  or exists (select 1 from parent_students ps join teacher_students ts on ts.student_id = ps.student_id
             where ps.parent_id = profiles.id and ts.teacher_id = auth.uid())
  or exists (select 1 from teacher_students ts join parent_students ps on ps.student_id = ts.student_id
             where ts.teacher_id = profiles.id and ps.parent_id = auth.uid()));
create policy p_profiles_self  on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = my_role());
create policy p_profiles_admin on profiles for all using (is_admin()) with check (is_admin());

-- students
create policy p_students_read  on students for select using (can_see_student(id));
create policy p_students_admin on students for all using (is_admin()) with check (is_admin());

-- links
create policy p_ps_read  on parent_students  for select using (parent_id = auth.uid() or is_staff_for(student_id));
create policy p_ps_admin on parent_students  for all using (is_admin()) with check (is_admin());
create policy p_ts_read  on teacher_students for select using (teacher_id = auth.uid() or is_admin());
create policy p_ts_admin on teacher_students for all using (is_admin()) with check (is_admin());

-- invitations: admin only
create policy p_inv_admin on invitations for all using (is_admin()) with check (is_admin());

-- skills catalog: readable by any signed-in user, edited by admin
create policy p_skills_read  on skills for select using (auth.uid() is not null);
create policy p_skills_admin on skills for all using (is_admin()) with check (is_admin());

-- program: parent/student read it through skill_map; staff read it; admin edits;
-- a teacher may set a manual colour for their own student.
create policy p_ss_read    on student_skills for select using (can_see_student(student_id));
create policy p_ss_admin   on student_skills for all using (is_admin()) with check (is_admin());
create policy p_ss_teacher on student_skills for update using (is_staff_for(student_id)) with check (is_staff_for(student_id));

-- assignments and items: visible to everyone who can see the child; admin creates them
create policy p_asg_read  on assignments for select using (can_see_student(student_id));
create policy p_asg_admin on assignments for all using (is_admin()) with check (is_admin());
create policy p_items_read on items for select using (
  exists (select 1 from assignments a where a.id = assignment_id and can_see_student(a.student_id)));
create policy p_items_admin on items for all using (is_admin()) with check (is_admin());

-- answer keys: staff only
create policy p_keys_staff on item_keys for select using (
  exists (select 1 from items i join assignments a on a.id = i.assignment_id
          where i.id = item_id and is_staff_for(a.student_id)));
create policy p_keys_admin on item_keys for all using (is_admin()) with check (is_admin());

-- attempts (right/wrong per answer): staff only. Parents see the colours of the skill map.
-- The child writes through submit_answer() and reads back through my_saved_answers().
create policy p_att_staff  on attempts for select using (is_staff_for(student_id));
create policy p_att_admin  on attempts for all using (is_admin()) with check (is_admin());

-- lessons: everyone who can see the child; staff manage them
create policy p_les_read  on lessons for select using (can_see_student(student_id));
create policy p_les_staff on lessons for all using (is_staff_for(student_id)) with check (is_staff_for(student_id));

-- feedback: staff write it; parents read only what was sent; the child doesn't see it
create policy p_fb_staff  on feedback for all using (is_staff_for(student_id)) with check (is_staff_for(student_id));
create policy p_fb_parent on feedback for select using (
  status = 'sent' and exists (select 1 from parent_students where parent_id = auth.uid() and student_id = feedback.student_id));

-- Parents must not read the teacher's raw notes or the AI draft, only the final text.
revoke select on feedback from authenticated;
grant select (id, lesson_id, student_id, final_text, locale, status, sent_at, created_at) on feedback to authenticated;
-- Staff read the full feedback (notes, draft) through this owner view.
create view feedback_staff as select * from feedback where is_staff_for(student_id);
grant select on feedback_staff to authenticated;

-- skill_map filters itself to staff and parents; children use my_skill_map(), which hides red.
revoke all on skill_map_all from anon, authenticated;
grant select on skill_map to authenticated;
grant execute on function submit_answer(uuid, text, int, int), my_saved_answers(uuid), my_skill_map(uuid) to authenticated;

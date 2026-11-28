-- Access test for schema.sql (fictional people only). Run on a fresh database after
-- supabase_stub.sql, schema.sql and skills.sql. Every check raises an error if it fails.
\set ON_ERROR_STOP 1

-- Fictional data ------------------------------------------------------------
insert into students (id, first_name, grade, state) values
  ('00000000-0000-0000-0000-00000000000a', 'Kid A', 3, 'NC'),
  ('00000000-0000-0000-0000-00000000000b', 'Kid B', 4, 'FL');

insert into invitations (email, role, display_name, student_ids) values
  ('admin@test',   'admin',   'Admin',   '{}'),
  ('teacher@test', 'teacher', 'Teacher', '{00000000-0000-0000-0000-00000000000a}'),
  ('pa@test',      'parent',  'Parent A','{00000000-0000-0000-0000-00000000000a}'),
  ('pb@test',      'parent',  'Parent B','{00000000-0000-0000-0000-00000000000b}'),
  ('kida@test',    'student', 'Kid A',   '{00000000-0000-0000-0000-00000000000a}');

insert into auth.users (id, email) values
  ('10000000-0000-0000-0000-000000000001', 'admin@test'),
  ('10000000-0000-0000-0000-000000000002', 'teacher@test'),
  ('10000000-0000-0000-0000-000000000003', 'pa@test'),
  ('10000000-0000-0000-0000-000000000004', 'pb@test'),
  ('10000000-0000-0000-0000-000000000005', 'kida@test'),
  ('10000000-0000-0000-0000-000000000006', 'stranger@test');   -- no invitation

insert into student_skills (student_id, skill_id, position) values
  ('00000000-0000-0000-0000-00000000000a', 'NC.3.MD.8', 1),
  ('00000000-0000-0000-0000-00000000000a', 'NC.3.OA.7', 2),
  ('00000000-0000-0000-0000-00000000000a', 'OLY.backwards', 3),
  ('00000000-0000-0000-0000-00000000000b', 'MA.4.FR.1.3', 1);

insert into assignments (id, student_id, kind, number, title) values
  ('20000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'homework', 1, 'HW A'),
  ('20000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'homework', 1, 'HW B');
insert into items (id, assignment_id, item_key, skill_id) values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-00000000000a', 'p1', 'NC.3.MD.8'),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-00000000000a', 'p2', 'NC.3.OA.7'),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-00000000000b', 'f1', 'MA.4.FR.1.3');
insert into item_keys values
  ('30000000-0000-0000-0000-000000000001', '24'),
  ('30000000-0000-0000-0000-000000000002', '63'),
  ('30000000-0000-0000-0000-000000000003', '4');

-- Perimeter: 5 right answers on 2 days -> green. Times tables: 1 of 3 -> red.
insert into attempts (student_id, item_id, answer, correct, created_at) values
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001', '24', true, now() - interval '3 days'),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001', '24', true, now() - interval '3 days'),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001', '24', true, now() - interval '1 day'),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001', '24', true, now() - interval '1 day'),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001', '20', false, now()),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000002', '56', false, now()),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000002', '63', true, now()),
  ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000002', '54', false, now());

insert into lessons (id, student_id, starts_at) values
  ('40000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', now());
insert into feedback (student_id, raw_notes, final_text, status) values
  ('00000000-0000-0000-0000-00000000000a', 'secret teacher notes', 'Great lesson!', 'sent'),
  ('00000000-0000-0000-0000-00000000000a', 'draft notes', null, 'draft');

-- Helper: fail unless a condition holds ----------------------------------------
create function pg_temp.expect(ok boolean, what text) returns void language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'FAILED: %', what; end if;
  raise notice 'ok: %', what;
end $$;

-- Signup trigger ----------------------------------------------------------------
select pg_temp.expect((select count(*) from profiles) = 5, 'invited users get a profile, stranger does not');
select pg_temp.expect((select profile_id from students where first_name = 'Kid A') = '10000000-0000-0000-0000-000000000005', 'student login linked');

-- As Parent A --------------------------------------------------------------------
set role authenticated;
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000003';
select pg_temp.expect((select count(*) from students) = 1, 'parent A sees only own child');
select pg_temp.expect((select count(*) from skill_map) = 3, 'parent A sees own child skill map');
select pg_temp.expect((select status from skill_map where skill_id = 'NC.3.MD.8') = 'green', 'perimeter is green');
select pg_temp.expect((select status from skill_map where skill_id = 'NC.3.OA.7') = 'red', 'times tables are red');
select pg_temp.expect((select status from skill_map where skill_id = 'OLY.backwards') = 'not_started', 'olympiad not started');
select pg_temp.expect((select count(*) from attempts) = 0, 'parent does not read individual answers');
select pg_temp.expect((select count(*) from item_keys) = 0, 'parent cannot read answer keys');
select pg_temp.expect((select count(*) from feedback) = 1, 'parent sees only sent feedback');
select pg_temp.expect((select final_text from feedback) = 'Great lesson!', 'parent reads final text');
do $$ begin
  perform raw_notes from feedback;
  raise exception 'FAILED: parent could read raw notes';
exception when insufficient_privilege then raise notice 'ok: parent cannot read raw notes';
end $$;
select pg_temp.expect((select count(*) from feedback_staff) = 0, 'parent sees nothing in feedback_staff');
update students set grade = 9;  -- must silently change nothing
select pg_temp.expect((select grade from students) = 3, 'parent cannot edit the student');

-- As Parent B --------------------------------------------------------------------
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000004';
select pg_temp.expect((select count(*) from skill_map where student_id = '00000000-0000-0000-0000-00000000000a') = 0, 'parent B cannot see kid A');
select pg_temp.expect((select count(*) from feedback) = 0, 'parent B cannot see kid A feedback');

-- As Kid A -----------------------------------------------------------------------
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000005';
select pg_temp.expect((select count(*) from attempts) = 0, 'child does not read own mistakes');
select pg_temp.expect((select count(*) from item_keys) = 0, 'child cannot read answer keys');
select pg_temp.expect((select count(*) from skill_map) = 0, 'child cannot read the coloured map directly');
select pg_temp.expect((select status from my_skill_map('00000000-0000-0000-0000-00000000000a') where skill_id = 'NC.3.OA.7') = 'locked', 'child sees red as locked');
select pg_temp.expect((select status from my_skill_map('00000000-0000-0000-0000-00000000000a') where skill_id = 'NC.3.MD.8') = 'unlocked', 'child sees green as unlocked');
select pg_temp.expect((select count(*) from my_skill_map('00000000-0000-0000-0000-00000000000b')) = 0, 'child cannot see another child map');
select pg_temp.expect((select count(*) from feedback) = 0, 'child does not see parent feedback');
select pg_temp.expect(submit_answer('30000000-0000-0000-0000-000000000002', ' 63 ') = true, 'server checks a right answer');
select pg_temp.expect(submit_answer('30000000-0000-0000-0000-000000000002', '64') = false, 'server checks a wrong answer');
select pg_temp.expect((select answer from my_saved_answers('20000000-0000-0000-0000-00000000000a') where item_key = 'p2') = '64', 'child restores latest saved answer');
do $$ begin
  perform submit_answer('30000000-0000-0000-0000-000000000003', '4');
  raise exception 'FAILED: child answered another child''s homework';
exception when raise_exception then
  if sqlerrm like 'FAILED%' then raise; end if;
  raise notice 'ok: child cannot answer another child''s homework';
end $$;
do $$ begin
  insert into attempts (student_id, item_id, answer, correct) values
    ('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000002', '1', true);
  raise exception 'FAILED: child wrote an attempt directly';
exception when insufficient_privilege then raise notice 'ok: child cannot fake a right answer';
end $$;
do $$ begin
  update profiles set role = 'admin' where id = auth.uid();
  if (select role from profiles where id = auth.uid()) = 'admin' then raise exception 'FAILED: child became admin'; end if;
  raise notice 'ok: child cannot make themselves admin';
exception when insufficient_privilege or check_violation then raise notice 'ok: child cannot make themselves admin';
end $$;

-- As Teacher (has kid A only) -------------------------------------------------------
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000002';
select pg_temp.expect((select count(*) from students) = 1, 'teacher sees only own students');
select pg_temp.expect((select count(*) from attempts) > 0, 'teacher sees mistakes');
select pg_temp.expect((select count(*) from item_keys) = 2, 'teacher reads answer keys of own student only');
select pg_temp.expect((select count(*) from feedback_staff) = 2, 'teacher reads notes and drafts');
select pg_temp.expect((select count(*) from profiles where role = 'parent') = 1, 'teacher sees only parents of own students');
update student_skills set override_status = 'green' where skill_id = 'NC.3.OA.7';
select pg_temp.expect((select status from skill_map where skill_id = 'NC.3.OA.7') = 'green', 'teacher can set a colour by hand');

-- As stranger (signed up without invitation) ------------------------------------------
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000006';
select pg_temp.expect((select count(*) from students) = 0, 'stranger sees no students');
select pg_temp.expect((select count(*) from skill_map) = 0, 'stranger sees no maps');

-- As Admin ----------------------------------------------------------------------------
set request.jwt.claim.sub = '10000000-0000-0000-0000-000000000001';
select pg_temp.expect((select count(*) from students) = 2, 'admin sees all students');
select pg_temp.expect((select count(*) from skill_map) = 4, 'admin sees all maps');
select pg_temp.expect((select count(*) from attempts) = 10, 'admin sees all answers');

reset role;
\echo ALL ACCESS CHECKS PASSED

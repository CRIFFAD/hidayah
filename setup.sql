-- Run in Supabase: SQL Editor > New query
create table if not exists public.enrollments(
  id bigint generated always as identity primary key,
  user_id uuid references auth.users on delete cascade not null,
  course_id text not null, course_title text not null,
  progress int default 0, created_at timestamptz default now(),
  unique(user_id, course_id));
create table if not exists public.messages(
  id bigint generated always as identity primary key,
  name text, email text, message text, created_at timestamptz default now());
alter table public.enrollments enable row level security;
alter table public.messages enable row level security;
create policy "own enrollments read" on public.enrollments for select using (auth.uid() = user_id);
create policy "own enrollments insert" on public.enrollments for insert with check (auth.uid() = user_id);
create policy "anyone can send message" on public.messages for insert with check (true);

-- ===== Roles, quizzes, scores and chat =====
create table if not exists public.profiles(
  id uuid primary key references auth.users on delete cascade,
  full_name text default '', email text, role text not null default 'student' check (role in ('student','teacher')),
  created_at timestamptz default now());
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,full_name,email) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email) on conflict do nothing; return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
insert into public.profiles(id,full_name,email) select id,coalesce(raw_user_meta_data->>'full_name',''),email from auth.users on conflict do nothing;
create or replace function public.is_teacher() returns boolean language sql security definer stable set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='teacher') $$;

create table if not exists public.quizzes(id uuid primary key default gen_random_uuid(), teacher_id uuid references public.profiles(id) on delete cascade,
  title text not null, subject text not null, level text, q_count int default 0, created_at timestamptz default now());
create table if not exists public.questions(id uuid primary key default gen_random_uuid(), quiz_id uuid references public.quizzes(id) on delete cascade,
  position int not null, text text not null, options jsonb not null);
create table if not exists public.answer_keys(question_id uuid primary key references public.questions(id) on delete cascade, correct int not null);
create table if not exists public.attempts(id bigint generated always as identity primary key, quiz_id uuid references public.quizzes(id) on delete cascade,
  student_id uuid references public.profiles(id) on delete cascade, score int, total int, xp int default 0, created_at timestamptz default now());
create table if not exists public.chat_messages(id bigint generated always as identity primary key, channel text not null,
  sender_id uuid references public.profiles(id) on delete cascade, body text not null check (char_length(body) between 1 and 1000), created_at timestamptz default now());

alter table public.profiles enable row level security; alter table public.quizzes enable row level security; alter table public.questions enable row level security;
alter table public.answer_keys enable row level security; alter table public.attempts enable row level security; alter table public.chat_messages enable row level security;
revoke update on public.profiles from anon, authenticated; grant update(full_name) on public.profiles to authenticated;
create policy "profiles read" on public.profiles for select using (auth.uid() is not null);
create policy "profiles update own" on public.profiles for update using (id=auth.uid());
create policy "quizzes read" on public.quizzes for select using (auth.uid() is not null);
create policy "quizzes delete own" on public.quizzes for delete using (teacher_id=auth.uid() and public.is_teacher());
create policy "questions read" on public.questions for select using (auth.uid() is not null);
create policy "keys teachers only" on public.answer_keys for select using (public.is_teacher());
create policy "attempts read" on public.attempts for select using (student_id=auth.uid() or public.is_teacher());
create policy "chat read" on public.chat_messages for select using (auth.uid() is not null);
create policy "chat send" on public.chat_messages for insert with check (sender_id=auth.uid() and (channel<>'announcements' or public.is_teacher()));

create or replace function public.create_quiz(p_title text,p_subject text,p_level text,p_qs jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare qid uuid; q jsonb; n int:=0; qq uuid;
begin
  if not public.is_teacher() then raise exception 'Only teachers can create quizzes'; end if;
  insert into quizzes(teacher_id,title,subject,level,q_count) values(auth.uid(),p_title,p_subject,p_level,jsonb_array_length(p_qs)) returning id into qid;
  for q in select * from jsonb_array_elements(p_qs) loop
    n:=n+1; insert into questions(quiz_id,position,text,options) values(qid,n,q->>'q',q->'options') returning id into qq;
    insert into answer_keys(question_id,correct) values(qq,(q->>'answer')::int);
  end loop; return qid;
end $$;

create or replace function public.submit_attempt(p_quiz uuid,p_answers int[]) returns jsonb language plpgsql security definer set search_path=public as $$
declare i int:=0; s int:=0; t int:=0; r record; corr int[]:='{}'; xp int;
begin
  if auth.uid() is null then raise exception 'Log in first'; end if;
  for r in select k.correct from questions q join answer_keys k on k.question_id=q.id where q.quiz_id=p_quiz order by q.position loop
    i:=i+1; t:=t+1; corr:=corr||r.correct; if p_answers[i]=r.correct then s:=s+1; end if;
  end loop;
  xp:=s*10+case when t>0 and s=t then 20 else 0 end;
  if exists(select 1 from attempts where quiz_id=p_quiz and student_id=auth.uid()) then xp:=0; end if;
  insert into attempts(quiz_id,student_id,score,total,xp) values(p_quiz,auth.uid(),s,t,xp);
  return jsonb_build_object('score',s,'total',t,'xp',xp,'correct',to_jsonb(corr));
end $$;

create or replace function public.leaderboard() returns table(name text,xp bigint,quizzes bigint) language sql security definer set search_path=public as $$
  select p.full_name,coalesce(sum(a.xp),0)::bigint,count(a.id)::bigint from profiles p join attempts a on a.student_id=p.id where p.role='student' group by p.id,p.full_name order by 2 desc limit 10 $$;

alter publication supabase_realtime add table public.chat_messages;
-- Make someone a teacher (run manually, one per teacher):
-- update public.profiles set role='teacher' where email='teacher@example.com';

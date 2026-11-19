-- Fresh Supabase project migration. Do not also run the legacy schema.sql.
begin;
create table public.profiles(id uuid primary key references auth.users on delete cascade, display_name text not null default '', tracks text[] not null default '{}' check(tracks <@ array['BCS','EEE']), created_at timestamptz not null default now());
create table public.user_roles(user_id uuid primary key references auth.users on delete cascade, role text not null check(role in ('admin','super_admin')));
create function public.is_staff() returns boolean language sql stable security definer set search_path='' as $$ select exists (select 1 from public.user_roles where user_id=auth.uid()) $$;
create function public.make_profile() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id) values(new.id) on conflict do nothing; return new; end $$;
create trigger new_student after insert on auth.users for each row execute function public.make_profile();
insert into public.profiles(id) select id from auth.users on conflict do nothing;
create table public.syllabus_versions(id bigint generated always as identity primary key, track text not null check(track in ('BCS','EEE')), version text not null, source_url text not null, verified_at timestamptz, unique(track,version));
create table public.subjects(id bigint generated always as identity primary key, syllabus_id bigint not null references public.syllabus_versions, name_bn text not null, name_en text not null, marks smallint check(marks>=0), unique(syllabus_id,name_en));
create table public.topics(id bigint generated always as identity primary key, subject_id bigint not null references public.subjects, chapter text not null, name text not null, unique(subject_id,chapter,name));
create table public.subtopics(id bigint generated always as identity primary key, topic_id bigint not null references public.topics, name text not null, unique(topic_id,name));
create table public.question_sources(id bigint generated always as identity primary key, citation text not null check(length(trim(citation))>0), source_url text, organization text, exam_year smallint check(exam_year between 1900 and 2200));
create table public.questions(id uuid primary key default gen_random_uuid(), subtopic_id bigint not null references public.subtopics, stem text not null check(length(trim(stem))>0), options text[] not null check(cardinality(options)=4 and array_ndims(options)=1 and array_lower(options,1)=1 and array_position(options,null) is null), correct_index smallint not null check(correct_index between 0 and 3), explanation text not null check(length(trim(explanation))>0), difficulty text not null check(difficulty in ('easy','medium','hard')), provenance text not null check(provenance in ('original','ai','unverified','verified')), source_id bigint references public.question_sources, reviewed_at timestamptz, reviewed_by uuid references auth.users, tags text[] not null default '{}', published boolean not null default false, check(provenance<>'verified' or (source_id is not null and reviewed_at is not null and reviewed_by is not null)));
create index question_filter on public.questions(subtopic_id,difficulty) where published;
create index question_search_v2 on public.questions using gin(to_tsvector('simple',stem));
create table public.exams(id uuid primary key default gen_random_uuid(), title text not null, track text not null check(track in ('BCS','EEE')), opens_at timestamptz not null, closes_at timestamptz not null, releases_at timestamptz not null, duration_minutes int not null check(duration_minutes between 1 and 300), question_count int not null check(question_count in (30,40,50,60,100)), points_per_question numeric(6,2) not null default 1 check(points_per_question>0), penalty numeric(6,2) not null default 0 check(penalty>=0), published boolean not null default false, check(opens_at<closes_at and closes_at<=releases_at));
-- Immutable question snapshots prevent edits to the bank from changing an assigned exam.
create table public.exam_questions(exam_id uuid references public.exams on delete cascade, position int check(position>0), question_id uuid not null references public.questions, subject text not null, topic text not null, stem text not null, options text[] not null check(cardinality(options)=4), correct_index smallint not null check(correct_index between 0 and 3), explanation text not null, primary key(exam_id,position), unique(exam_id,question_id));
create table public.exam_sessions(id uuid primary key default gen_random_uuid(), exam_id uuid not null references public.exams, student_id uuid not null references auth.users on delete cascade, started_at timestamptz not null, deadline timestamptz not null, submitted_at timestamptz, unique(exam_id,student_id), unique(id,exam_id));
create index session_deadlines on public.exam_sessions(deadline) where submitted_at is null;
create table public.exam_answers(session_id uuid, exam_id uuid not null, position int, picked smallint check(picked between 0 and 3), marked boolean not null default false, primary key(session_id,position), foreign key(session_id,exam_id) references public.exam_sessions(id,exam_id) on delete cascade, foreign key(exam_id,position) references public.exam_questions(exam_id,position));
create table public.exam_results(session_id uuid primary key references public.exam_sessions on delete cascade, correct int not null, wrong int not null, skipped int not null, score numeric not null, duration_seconds int not null);
create table public.study_routines(id uuid primary key default gen_random_uuid(), student_id uuid not null default auth.uid() references auth.users on delete cascade, starts_on date not null, track text not null check(track in ('BCS','EEE','both')));
create table public.routine_tasks(id uuid primary key default gen_random_uuid(), routine_id uuid not null references public.study_routines on delete cascade, topic_id bigint references public.topics, title text not null, starts_at timestamptz not null, minutes int not null check(minutes>0), mcq_target int not null check(mcq_target>=0), completed_at timestamptz);
create index routine_task_order on public.routine_tasks(routine_id,starts_at);
create table public.bookmarks(student_id uuid not null default auth.uid() references auth.users on delete cascade, question_id uuid not null references public.questions on delete cascade, primary key(student_id,question_id));
create table public.revision_items(id uuid primary key default gen_random_uuid(), student_id uuid not null default auth.uid() references auth.users on delete cascade, question_id uuid not null references public.questions on delete cascade, due_on date not null, completed_at timestamptz, unique(student_id,question_id,due_on));
create table public.student_progress(student_id uuid not null default auth.uid() references auth.users on delete cascade, subtopic_id bigint not null references public.subtopics on delete cascade, completed_at timestamptz not null default now(), primary key(student_id,subtopic_id));
create table public.announcements(id uuid primary key default gen_random_uuid(), title text not null, body text not null, published_at timestamptz);
do $$ declare t text; begin foreach t in array array['profiles','user_roles','syllabus_versions','subjects','topics','subtopics','question_sources','questions','exams','exam_questions','exam_sessions','exam_answers','exam_results','study_routines','routine_tasks','bookmarks','revision_items','student_progress','announcements'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid());
create policy profile_edit on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy own_role on public.user_roles for select to authenticated using(user_id=auth.uid());
create policy exam_schedule on public.exams for select using(published or public.is_staff());
create policy announcement_read on public.announcements for select using(published_at<=now());
do $$ declare t text; begin foreach t in array array['syllabus_versions','subjects','topics','subtopics'] loop execute format('create policy catalog_read on public.%I for select using (true)',t); end loop; foreach t in array array['syllabus_versions','subjects','topics','subtopics','question_sources','questions','announcements'] loop execute format('create policy staff_manage on public.%I for all to authenticated using(public.is_staff()) with check(public.is_staff())',t); end loop; foreach t in array array['study_routines','bookmarks','revision_items','student_progress'] loop execute format('create policy own_records on public.%I for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid())',t); end loop; end $$;
create policy own_tasks on public.routine_tasks for all to authenticated using(exists(select 1 from public.study_routines r where r.id=routine_id and r.student_id=auth.uid())) with check(exists(select 1 from public.study_routines r where r.id=routine_id and r.student_id=auth.uid()));
-- No public/learner direct policies on answer keys, session writes or results.
create function public.enter_live(p_exam uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.exams; s public.exam_sessions; t timestamptz:=clock_timestamp(); payload jsonb;
begin
 if auth.uid() is null then raise exception 'sign_in_required'; end if;
 select * into e from public.exams where id=p_exam and published;
 if not found or t<e.opens_at or t>=e.closes_at then raise exception 'exam_closed'; end if;
 if (select count(*) from public.exam_questions where exam_id=p_exam)<>e.question_count then raise exception 'invalid_question_count'; end if;
 insert into public.exam_sessions(exam_id,student_id,started_at,deadline) values(p_exam,auth.uid(),t,least(e.closes_at,t+make_interval(mins=>e.duration_minutes))) on conflict(exam_id,student_id) do nothing;
 select * into s from public.exam_sessions where exam_id=p_exam and student_id=auth.uid();
 if s.submitted_at is not null or clock_timestamp()>=s.deadline then raise exception 'attempt_closed'; end if;
 select jsonb_agg(jsonb_build_object('position',q.position,'stem',q.stem,'options',q.options,'picked',a.picked,'marked',coalesce(a.marked,false)) order by q.position) into payload from public.exam_questions q left join public.exam_answers a on a.session_id=s.id and a.position=q.position where q.exam_id=p_exam;
 return jsonb_build_object('session_id',s.id,'deadline',s.deadline,'server_time',clock_timestamp(),'questions',payload);
end $$;
create function public.save_live_answer(p_session uuid,p_position int,p_picked smallint,p_marked boolean) returns void language plpgsql security definer set search_path='' as $$
declare s public.exam_sessions;
begin
 select * into s from public.exam_sessions where id=p_session and student_id=auth.uid() for update;
 if not found or s.submitted_at is not null or clock_timestamp()>=s.deadline then raise exception 'attempt_closed'; end if;
 insert into public.exam_answers(session_id,exam_id,position,picked,marked) values(s.id,s.exam_id,p_position,p_picked,p_marked) on conflict(session_id,position) do update set picked=excluded.picked,marked=excluded.marked;
end $$;
create function public.finish_exam_internal(p_session uuid,p_student uuid,p_expired_only boolean) returns void language plpgsql security definer set search_path='' as $$
declare s public.exam_sessions; t timestamptz;
begin
 select * into s from public.exam_sessions where id=p_session and (p_expired_only or student_id=p_student) for update;
 if not found then raise exception 'attempt_not_found'; end if;
 t:=clock_timestamp();
 if s.submitted_at is not null or (p_expired_only and t<s.deadline) then return; end if;
 update public.exam_sessions set submitted_at=least(t,s.deadline) where id=s.id;
 insert into public.exam_results select s.id,count(*) filter(where a.picked=q.correct_index), count(*) filter(where a.picked<>q.correct_index),count(*) filter(where a.picked is null), coalesce(sum(case when a.picked=q.correct_index then e.points_per_question when a.picked is not null then -e.penalty else 0 end),0), greatest(0,floor(extract(epoch from least(t,s.deadline)-s.started_at))::int)
 from public.exam_questions q join public.exams e on e.id=q.exam_id left join public.exam_answers a on a.session_id=s.id and a.position=q.position where q.exam_id=s.exam_id;
end $$;
create function public.submit_live(p_session uuid) returns void language sql security definer set search_path='' as $$ select public.finish_exam_internal(p_session,auth.uid(),false) $$;
create function public.finalize_expired() returns int language plpgsql security definer set search_path='' as $$
declare sid uuid; n int:=0; begin for sid in select id from public.exam_sessions where submitted_at is null and deadline<=clock_timestamp() order by deadline limit 200 for update skip locked loop perform public.finish_exam_internal(sid,null,true); n:=n+1; end loop; return n; end $$;
create function public.live_result(p_session uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.exam_sessions; e public.exams; summary jsonb; details jsonb;
begin
 select * into s from public.exam_sessions where id=p_session and student_id=auth.uid(); if not found then raise exception 'attempt_not_found'; end if;
 select * into e from public.exams where id=s.exam_id;
 if clock_timestamp()<e.releases_at then raise exception 'result_not_released'; end if;
 perform public.finish_exam_internal(s.id,null,true);
 select to_jsonb(r) into summary from public.exam_results r where r.session_id=s.id;
 select jsonb_agg(jsonb_build_object('position',q.position,'subject',q.subject,'topic',q.topic,'stem',q.stem,'options',q.options,'picked',a.picked,'correct_index',q.correct_index,'explanation',q.explanation) order by q.position) into details from public.exam_questions q left join public.exam_answers a on a.session_id=s.id and a.position=q.position where q.exam_id=s.exam_id;
 return jsonb_build_object('summary',summary,'questions',details);
end $$;
revoke execute on function public.make_profile(),public.finish_exam_internal(uuid,uuid,boolean),public.finalize_expired(),public.enter_live(uuid),public.save_live_answer(uuid,int,smallint,boolean),public.submit_live(uuid),public.live_result(uuid) from public,anon,authenticated;
grant execute on function public.enter_live(uuid),public.save_live_answer(uuid,int,smallint,boolean),public.submit_live(uuid),public.live_result(uuid) to authenticated;
grant execute on function public.finalize_expired() to service_role;
commit;

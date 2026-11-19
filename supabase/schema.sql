-- Deploy manually after connecting Supabase. This schema is not used by the local preview.
create table public.question_bank (
 id uuid primary key default gen_random_uuid(), track text not null check(track in ('BCS','EEE')), subject text not null, topic text not null, subtopic text not null,
 organization text, exam_category text, exam_year int, stem text not null, options text[] not null check(cardinality(options)=4), correct_index int not null check(correct_index between 0 and 3),
 explanation text not null, source text not null, difficulty text not null check(difficulty in ('Easy','Medium','Hard')),
 provenance text not null check(provenance in ('original','ai_practice','unverified','verified')), reviewed_at timestamptz, reviewed_by uuid references auth.users,
 check(provenance <> 'verified' or (exam_year is not null and reviewed_by is not null and reviewed_at is not null))
);
create index question_taxonomy on public.question_bank(track,subject,topic,subtopic);
create index question_paper on public.question_bank(organization,exam_category,exam_year) where provenance='verified';
create index question_search on public.question_bank using gin(to_tsvector('simple',stem));
alter table public.question_bank enable row level security;
create policy staff_read on public.question_bank for select to authenticated using ((auth.jwt()->'app_metadata'->>'role') = 'admin');
create policy staff_write on public.question_bank for all to authenticated using ((auth.jwt()->'app_metadata'->>'role') = 'admin') with check ((auth.jwt()->'app_metadata'->>'role') = 'admin');
-- Practice clients should receive selected question fields through a server endpoint that does not send the answer key before grading.
create table public.study_tasks (id uuid primary key default gen_random_uuid(), owner uuid not null default auth.uid() references auth.users on delete cascade, subject text not null, topic text not null, due_on date not null, minutes int not null check(minutes>0), mcq_target int not null check(mcq_target>=0), position int not null default 0, completed boolean not null default false);
create index task_owner_date on public.study_tasks(owner,due_on,position);
alter table public.study_tasks enable row level security;
create policy own_tasks on public.study_tasks for all to authenticated using (owner=auth.uid()) with check(owner=auth.uid());
create table public.exam_attempts (id uuid primary key default gen_random_uuid(), owner uuid not null references auth.users on delete cascade, created_at timestamptz not null default now(), track text not null check(track in ('BCS','EEE')), penalty numeric not null check(penalty>=0), submitted_at timestamptz);
create index attempt_owner_date on public.exam_attempts(owner,created_at desc);
alter table public.exam_attempts enable row level security;
create policy own_attempt_reads on public.exam_attempts for select to authenticated using (owner=auth.uid());
create table public.attempt_answers (attempt_id uuid not null references public.exam_attempts on delete cascade, question_id uuid not null references public.question_bank, picked_index int check(picked_index between 0 and 3), correct boolean, primary key(attempt_id,question_id));
alter table public.attempt_answers enable row level security;
create policy own_answer_reads on public.attempt_answers for select to authenticated using (exists(select 1 from public.exam_attempts where id=attempt_id and owner=auth.uid() and submitted_at is not null));

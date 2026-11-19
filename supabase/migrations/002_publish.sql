begin;
create function public.publish_live(p_exam uuid,p_ids uuid[]) returns void language plpgsql security definer set search_path='' as $$
declare e public.exams; n int;
begin
 if not public.is_staff() then raise exception 'staff_required'; end if;
 select * into e from public.exams where id=p_exam for update;
 if not found or e.published or clock_timestamp()>=e.opens_at then raise exception 'not_publishable'; end if;
 if coalesce(cardinality(p_ids),0)<>e.question_count then raise exception 'invalid_question_count'; end if;
 insert into public.exam_questions(exam_id,position,question_id,subject,topic,stem,options,correct_index,explanation)
 select e.id,x.pos,q.id,s.name_en,t.name,q.stem,q.options,q.correct_index,q.explanation from unnest(p_ids) with ordinality x(id,pos)
 join public.questions q on q.id=x.id and q.published join public.subtopics st on st.id=q.subtopic_id join public.topics t on t.id=st.topic_id join public.subjects s on s.id=t.subject_id join public.syllabus_versions v on v.id=s.syllabus_id and v.track=e.track;
 get diagnostics n=row_count;
 if n<>e.question_count then raise exception 'invalid_question_selection'; end if;
 update public.exams set published=true where id=e.id;
end $$;
-- Staff can create and edit drafts, but cannot change a published exam or bypass snapshot validation.
create policy exam_draft_insert on public.exams for insert to authenticated with check(public.is_staff() and not published);
create policy exam_draft_update on public.exams for update to authenticated using(public.is_staff() and not published) with check(public.is_staff() and not published);
create policy exam_draft_delete on public.exams for delete to authenticated using(public.is_staff() and not published);
revoke execute on function public.publish_live(uuid,uuid[]) from public,anon,authenticated;
grant execute on function public.publish_live(uuid,uuid[]) to authenticated;
commit;

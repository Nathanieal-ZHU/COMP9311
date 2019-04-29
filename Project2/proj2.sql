 --Q1:
drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
declare
RoomRecord RoomRecord;
enrolled_students integer;
waiting_students integer;
valid_room_number integer;
bigger_room_number integer;

Begin
	if (course_id in (select id from Courses)) then
		enrolled_students := (
			select count(*) 
			from course_enrolments ce 
			where ce.course = course_id);
		waiting_students := (
			select count(*) 
			from course_enrolment_waitlist 
			where course_id = course);
		valid_room_number := (
			select count(*) 
			from rooms r 
			where enrolled_students <= r.capacity);
		bigger_room_number := (
			select count(*) 
			from rooms r 
			where r.capacity >= (waiting_students + enrolled_students));
		RoomRecord.valid_room_number := valid_room_number;
		RoomRecord.bigger_room_number := bigger_room_number;
		return RoomRecord;
	else
		RAISE EXCEPTION 'INVALID COURSEID';
	end if;

end;

$$ language plpgsql;


--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare
i 	record;
teachrecord TeachingRecord;
course_id integer;

Begin
if (staff_id in (select id from staff)) then
	for i in (
		select ce.course as course
		from course_staff cs 
		join course_enrolments ce 
		on cs.course = ce.course
		where staff = staff_id 
		and ce.mark is not null
		group by staff,ce.course
		having count(*) > 0
		order by course asc)
	loop
		teachrecord.cid = i.course;

		teachrecord.term = (
			select LOWER(right(sem.year::text,2)||sem.term)
			from ((Courses c 
				join Subjects s 
				on s.id = c.subject) 
				join Semesters sem 
				on sem.id = c.semester)
			where c.id = i.course);

		teachrecord.code = (
			select s.code
			from ((Courses c 
				join Subjects s 
				on s.id = c.subject) 
				join Semesters sem
				on sem.id = c.semester)
			where c.id = i.course);

		teachrecord.name = (
			select s.name
			from ((Courses c 
				join Subjects s 
				on s.id = c.subject) 
				join Semesters sem
				on sem.id = c.semester)
			where c.id = i.course);

		teachrecord.uoc = (
			select s.uoc
			from ((Courses c 
				join Subjects s 
				on s.id = c.subject) 
				join Semesters sem
				on sem.id = c.semester)
			where c.id = i.course);

		teachrecord.average_mark = (
			select round(AVG(ce.mark))
			from course_enrolments ce
			where ce.course = i.course
			and ce.mark is not null
			group by ce.course);

		teachrecord.highest_mark = (
			select MAX(mark)
			from course_enrolments ce
			where ce.course = i.course
			and ce.mark is not null
			group by ce.course);

		teachrecord.median_mark = (
			select * 
			from Median_mark(i.course));

		teachrecord.totalEnrols = (
			select count(*)
			from course_enrolments ce
			where ce.course = i.course
			and ce.mark is not null
			group by ce.course);

		return next teachrecord;

		end loop;
else
	RAISE EXCEPTION 'INVALID STAFFID';
end if;
end;
$$ language plpgsql;

create or replace function Median_mark(cid integer)
	returns integer
as $$
declare
median integer := 0;
flag integer := 0;
total integer;
r  record;
Begin
total = (
	select count(mark) 
	from course_enrolments 
	where course = cid 
	and mark is not null 
	group by course);
for r in (
	select mark 
	from course_enrolments 
	where course = cid 
	and mark is not null 
	order by mark)
loop
	flag = flag + 1;
	if (total % 2 = 1) then 
		if flag = ((total+1)/2) then 
			median := r.mark;
			return median;
			end if;
	else 
		if flag = (total/2 + 1) then
			median = median + r.mark;
			return round(median/2);
			end if;
		if flag = (total/2) then
			median = median + r.mark;
			end if;
	end if;
end loop;
end;

$$ language plpgsql;


--Q3:
drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer,min_score integer) 
  returns setof CourseRecord
as $$
declare
cr CourseRecord;
i record;

Begin

if (org_id not in (select id from orgunits))
then RAISE EXCEPTION 'INVALID ORGID';

else
for i in( 
  select * 
  from(
  (select p.unswid
    from Subjects sub, course_enrolments ce, courses c, people p, semesters sem,(
    with recursive r as(
      select * 
      from orgunit_groups
      where owner = org_id
    union all
      select orgunit_groups.*
      from orgunit_groups,r
      where orgunit_groups.owner = r.member
      and r.member <> 0)
    select * 
    from r) as all_sub_org
  where c.subject = sub.id
  and c.id = ce.course
  and ce.student = p.id
  and sem.id = c.semester
  and (sub.offeredby = all_sub_org.member or sub.offeredby = org_id)
  group by p.unswid,ce.mark
  having ce.mark >= min_score)
  intersect
  (select p.unswid
    from courses c, course_enrolments ce, people p, Subjects sub, (
      with recursive r as (
        select * 
        from orgunit_groups
        where owner = org_id
      union all
        select orgunit_groups.*
        from orgunit_groups,r
        where orgunit_groups.owner = r.member
        and r.member <> 0)
      select * from r)
    as all_sub_org
    where c.subject = sub.id
    and c.id = ce.course
    and ce.student = p.id
    and (sub.offeredby = all_sub_org.member or sub.offeredby = org_id)
    group by p.unswid
    having count(distinct c.id) > num_courses)) as get_unswid)
loop
  cr.unswid = i.unswid;
  cr.student_name = (
    select p.name
    from people p
    where p.unswid = i.unswid);
  cr.course_records = (select * from course_records(i.unswid,org_id));
  return next cr;
end loop;
end if;
end;
$$ language plpgsql;

create or replace function course_records(unsw_id integer, org_id integer)
  returns text
  as $$
  declare
  i record;
  flag integer := 0;
  output text := '';
  name text := '';
  code text := '';
  orgunits_name text := '';
  semester_name text := '';
  mark text := '';

  Begin
  for i in
  select *
  from(
    select c.semester, sub.code
    from course_enrolments ce, courses c, people p, Subjects sub,(
      with recursive r as (
        select *
        from orgunit_groups
        where owner = org_id
      union all
        select orgunit_groups.*
        from orgunit_groups,r
        where orgunit_groups.owner = r.member
        and r.member <> 0)
      select * from r ) 
      as all_sub_org
    where unsw_id = p.unswid
    and c.id = ce.course
    and ce.student = p.id
    and sub.id = c.subject
    and (sub.offeredby = all_sub_org.member or sub.offeredby = org_id)
    order by ce.mark desc nulls last,c.id asc nulls last) as get_course
  loop
  flag := flag + 1;
  exit when flag >= 6;
  code := (
    select sub.code
    from course_enrolments ce, courses c, Subjects sub, people p
    where p.unswid = unsw_id
    and ce.student = p.id
    and c.id = ce.course
    and c.subject = sub.id
    and i.code = sub.code
    and c.semester = i.semester);
  name := (
    select sub.name
    from course_enrolments ce, courses c, Subjects sub, people p
    where p.unswid = unsw_id
    and ce.student = p.id
    and c.id = ce.course
    and c.subject = sub.id
    and i.code = sub.code
    and c.semester = i.semester);
  orgunits_name := (
    select o.name
    from course_enrolments ce, courses c, Subjects sub, people p, orgunits o
    where p.unswid = unsw_id
    and ce.student = p.id
    and c.id = ce.course
    and c.subject = sub.id
    and i.code = sub.code
    and c.semester = i.semester
    and o.id = sub.offeredby);
  semester_name := (
    select sub.code
    from course_enrolments ce, courses c, Subjects sub, people p, semesters sem
    where p.unswid = unsw_id
    and ce.student = p.id
    and c.id = ce.course
    and c.subject = sub.id
    and i.code = sub.code
    and c.semester = i.semester
    and sem.id = c.semester);
  mark := (
    select ce.mark
    from course_enrolments ce, courses c, Subjects sub, people p
    where p.unswid = unsw_id
    and ce.student = p.id
    and c.id = ce.course
    and c.subject = sub.id
    and i.code = sub.code
    and c.semester = i.semester);
  if mark is null
  then mark := 'null';
  end if;
  output := output||display(code,name,semester_name,orgunits_name,mark);
end loop;
return output;
end;
$$ language plpgsql;

create or replace function display(
  code text, name text, semester_name text, orgunits_name text, mark text)
  returns text
as $$
begin 
  return code ||', '||name ||', '||semester_name ||', '||orgunits_name ||', '||mark||E'\n';
end;
$$ language plpgsql;

select * from q3(52,35,100);

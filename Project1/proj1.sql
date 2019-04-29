-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: 
create or replace view Q1(unswid, name)
as

select p.name,p.unswid
from people p,course_enrolments c,Students s
where c.mark>=85
and s.stype='intl'
and s.id=p.id
and c.student=s.id
group by p.name,p.unswid
having count(c.course)>20
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: 
create or replace view Q2(unswid, name)
as
select r.unswid,r.longname as name
from Rooms r
left join buildings b on r.building=b.id
left join room_types rt on rt.id=r.rtype
where 
r.capacity>=20
and b.name='Computer Science Building'
and rt.description='Meeting Room'

--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: 
create or replace view Q3(unswid, name)
as
select p.unswid,p.name
from people p
left join staff s on p.unswid=s.id
left join course_staff cs on cs.staff=p.id
left join course_enrolments ce on cs.course=ce.course
where ce.student in(select p.id from people p where p.name='Stefan Bilek')
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4:
create or replace view Q4(unswid, name)
as
select p.unswid,p.name
from people p 
left join course_enrolments ce on ce.student=p.id
left join subjects s on s.id=c.subject
left join courses c on c.id=ce.course
where s.code='COMP3331'
except(
select p.unswid,p.name
from people p 
left join course_enrolments ce on ce.student=p.id
left join subjects s on s.id=c.subject
left join courses c on c.id=ce.course
where s.code='COMP3231'
)
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: 
create or replace view Q5a(num)
as
select count(distinct stu.id)
from students stu
inner join program_enrolments pe on pe.student=stu.id
inner join semesters s on s.id=pe.semester
inner join stream_enrolments se on se.partof=pe.id
inner join streams str on str.id=se.stream
where str.name='Chemistry'
and stu.stype='local'
and s.year='2011'
and s.term='S1'
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q5: 
create or replace view Q5b(num)
as
select count(distinct stu.id)
from students stu
inner join program_enrolments pe on pe.student=stu.id
inner join semesters s on s.id=pe.semester
inner join programs p on p.id=pe.program
inner join orgunits o on o.id=p.offeredby
where stu.stype='intl'
and o.longname='School of Computer Science and Engineering' 
and s.year='2011'
and s.term='S1'
--... SQL statements, possibly using other views/functions defined by you ...
;


-- Q6:
create or replace function Q6(text) returns text
as $$
select Subjects.code||' '||Subjects.name||' '||Subjects.uoc
from Subjects
where Subjects.code=($1)
$$ language sql
;
--... SQL statements, possibly using other views/functions defined by you ...




-- Q7: 
create or replace view intl(id,num)
as
select p.id,count(*)
from programs p,program_enrolments pe,students stu
where pe.student=stu.id
and pe.program=p.id
and stu.stype='intl'
group by p.id;

create or replace view total(id,num)
as
select p.id,count(*)
from programs p,program_enrolments pe,students stu
where pe.student=stu.id
and pe.program=p.id
group by p.id;

create or replace view Q7(code, name)
as
select p.code,p.name
from 
(select intl.id,((intl.num*1.0)/(total.num*1.0)) as percent
from intl,total
where intl.id=total.id) as p1, programs p,intl,total
where p1.percent>0.5
and p1.id=intl.id
and p1.id=total.id
and p.id=p1.id
;
--... SQL statements, possibly using other views/functions defined by you ...




-- Q8:
create or replace view Q8(code, name, semester)
as
select s.code , s.name, se.name as semester
from  courses c,course_enrolments ce,semesters se,subjects s
where c.subject=s.id 
and c.semester=se.id 
and ce.course=c.id 
and ce.mark is not null
group by s.code,s.name,se.name
having avg(ce.mark)=
(select max(m) as max
from 
(select avg(ce.mark) as m
from courses c,course_enrolments ce,semesters se,subjects s
where c.subject=s.id 
and c.semester=se.id 
and ce.course=c.id 
and ce.mark is not null
group by c.id
having count(ce.mark)>=15
order by m) as avg_mark
);
--... SQL statements, possibly using other views/functions defined by you ...


-- Q9:
create or replace view Q9(name, school, email, starting, num_subjects)
as
select p.name,o.longname,p.email,a.starting,count(s.code)
from People p,orgunits o,affiliations a,subjects s,courses c,course_staff cs,staff_roles sr,orgunit_types ot
where p.id=cs.staff 
and p.id=a.staff
and o.id=a.orgunit
and cs.course=c.id
and a.role=sr.id 
and s.id=c.subject 
and sr.name='Head of School' 
and a.ending is null 
and ot.name='School'
and a.isprimary='t'
group by p.name,o.longname,p.email,a.starting
having count(s.code)>0;
--... SQL statements, possibly using other views/functions defined by you ...




-- Q10:
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select sub.code
from subjects sub,semesters sem,courses c
where sem.id=c.semester
and sub.id=c.subject
and c.semester in (select id from sem where year>=2003 and year<=2012)
and c.subject in (select id from sub where code like 'COMP93%')
group by sub.code
having count(*)=20 
--ensure offered in every semester
;

create or replace view HD_1s(course,code,percent,year)
as
select sub.code,sub.name,sem.year,
cast(sum(case when ce.mark>=85 then 1 else 0 end)*1.0/count(*)*1.0 as numeric(4,2))
from course_enrolments ce,subjects sub,courses c,semesters sem,HD1_class
where  ce.course=c.id
and c.subject=sub.id
and sub.code=HD1_class.code
and c.semester=sem.id
and sub.code like 'COMP93%'
and sem.term='S1'
and sem.year>=2003
and sem.year<=2012
and ce.mark>=0
group by sub.name,sem.year,sub.code
order by sub.code,sem.year
;
create or replace view HD_2s(course,code,percent,year)
as
select sub.code,sub.name,sem.year,
cast(sum(case when ce.mark>=85 then 1 else 0 end)*1.0/count(*)*1.0 as numeric(4,2))
from course_enrolments ce,subjects sub,courses c,semesters sem,HD1_class
where  ce.course=c.id
and c.subject=sub.id
and sub.code=HD1_class.code
and c.semester=sem.id
and sub.code like 'COMP93%'
and sem.term='S2'
and sem.year>=2003
and sem.year<=2012
and ce.mark>=0
group by sub.name,sem.year,sub.code
order by sub.code,sem.year
;
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select HD_1s.course,HD_1s.code,right(HD_1s.percent::text,2),HD_1s.year,HD_2s.year
from HD_1s
left join HD_2s
on HD_1s.course=HD_2s.course
and HD_1s.code=HD_2s.code
and HD_1s.percent=HD_2s.percent
--... SQL statements, possibly using other views/functions defined by you ...
;
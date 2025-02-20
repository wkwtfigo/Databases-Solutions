create view unoverridden as
select *
from takes t1
where t1.grade = 'F' and not exists (
    select *
    from takes t2
    where t1.id = t2.id 
    and t1.course_id = t2.course_id 
    and t1.sec_id = t2.sec_id 
    and t2.grade in ('A', 'B', 'C', 'D')
);
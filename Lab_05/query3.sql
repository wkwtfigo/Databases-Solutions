select s.course_id, s.sec_id, coalesce(count(t.id), 0) as number_of_students
from section s
left join takes t
	on s.course_id = t.course_id
	and s.sec_id = t.sec_id
	and s.semester = t.semester
	and s.year = t.year
group by s.course_id, s.sec_id, s.semester, s.year

create table grade_mapping (
    grade VARCHAR(1) PRIMARY KEY,
    value NUMERIC(2, 1) not null
);

insert into grade_mapping (grade, value)
values 
  ('A', 4), ('A+', 4), ('A-', 4),
    ('B', 3), ('B+', 3), ('B-', 3),
    ('C', 2), ('C+', 2), ('C-', 2),
    ('D', 1), ('D+', 1), ('D-', 1),
    ('F', 0);

select s.id, s.name,
	case
		when sum(case 
			when t.grade is null then 1 else 0 end) > 0
		then null
		else round(sum(g.value) / count(t.course_id), 2)
	end as GPA
from student s
left join takes t on s.id = t.id
join grade_mapping g on t.grade = g.grade
group by s.id, s.name;
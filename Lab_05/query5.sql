select s.id, s.name
from student s
join takes t on s.id = t.id
where t.grade = 'F'
group by s.id, s.name
having count(*) >= 2;
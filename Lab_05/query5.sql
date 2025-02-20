select student.id, student.name
from student
join unoverridden on student.id = unoverridden.id
group by student.id, student.name
having count(*) >= 2; 
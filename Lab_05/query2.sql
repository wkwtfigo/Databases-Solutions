select student.id as id, student.name as name 
from student, takes
where student.id = takes.id and
  course_id = 'BIO-301';
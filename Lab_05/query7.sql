select max(student_count) as max_enrollment
from (
  select count(id) as student_count
  from takes
  where semester = 'Spring'
  group by course_id, sec_id, semester, year
) as section_counts;
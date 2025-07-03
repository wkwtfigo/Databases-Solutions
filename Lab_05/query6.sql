select max(student_count) as max_enrollment
from (
    select count(*) as student_count
    from takes
    group by course_id, sec_id, semester, year
) as enrollment;
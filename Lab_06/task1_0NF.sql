CREATE TABLE project_assignment (
    project_code VARCHAR(10),
    project_name VARCHAR(50),
    project_manager VARCHAR(50),
    project_budget NUMERIC(10,2),
    employee_no INT,
    employee_name VARCHAR(50),
    department_no VARCHAR(10),
    department_name VARCHAR(50),
    hourly_rate NUMERIC(5,2),
    PRIMARY KEY (project_code, employee_no)
);

-- we can assume that one employee can be assigned to several projects at the same type, so employee_no is not unique
-- project_code is not unique too, so we use (project_code, employee_no) as primary key

INSERT INTO project_assignment_raw VALUES 
('PC010', 'Reservation System', 'Mr. Ajay', 120500, 100, 'Mohan', 'D03', 'Database', 21.00),
('PC010', 'Reservation System', 'Mr. Ajay', 120500, 101, 'Vipul', 'D02', 'Testing', 16.50),
('PC010', 'Reservation System', 'Mr. Ajay', 120500, 102, 'Riyaz', 'D01', 'IT', 22.00),
('PC011', 'HR System', 'Mrs. Charu', 500500, 105, 'Pavel', 'D03', 'Database', 18.50),
('PC011', 'HR System', 'Mrs. Charu', 500500, 103, 'Jack', 'D02', 'Testing', 17.00),
('PC011', 'HR System', 'Mrs. Charu', 500500, 104, 'James', 'D01', 'IT', 23.50),
('PC012', 'Attendance System', 'Mr. Rajesh', 710700, 315, 'Rlau', 'D03', 'Database', 21.50),
('PC012', 'Attendance System', 'Mr. Rajesh', 710700, 218, 'Alex', 'D02', 'Testing', 15.50),
('PC012', 'Attendance System', 'Mr. Rajesh', 710700, 109, 'Victor', 'D01', 'IT', 20.50);
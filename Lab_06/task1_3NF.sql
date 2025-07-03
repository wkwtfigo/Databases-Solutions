create table project (
    project_code VARCHAR(10),
    project_name VARCHAR(50),
    project_manager VARCHAR(50),
    project_budget NUMERIC(10,2),
    primary key (project_code)
);

create table employee (
    employee_no INT,
    employee_name VARCHAR(50),
    department_no VARCHAR(10),
    hourly_rate NUMERIC(5,2),
    primary key (employee_no)
);

create table assignment (
    project_code VARCHAR(10),
    employee_no INT,
    primary key (project_code, employee_no),
    foreign key (project_code) references project(project_code),
    foreign key (employee_no) references employee(employee_no)
);

create table department (
    department_no VARCHAR(10),
    department_name VARCHAR(50),
    primary key (department_no)
);

INSERT INTO project VALUES 
('PC010', 'Reservation System', 'Mr. Ajay', 120500),
('PC011', 'HR System', 'Mrs. Charu', 500500),
('PC012', 'Attendance System', 'Mr. Rajesh', 710700);

INSERT INTO employee VALUES 
(100, 'Mohan', 'D03', 21.00),
(101, 'Vipul', 'D02', 16.50),
(102, 'Riyaz', 'D01', 22.00),
(105, 'Pavel', 'D03', 18.50),
(103, 'Jack', 'D02', 17.00),
(104, 'James', 'D01', 23.50),
(315, 'Rlau', 'D03', 21.50),
(218, 'Alex', 'D02', 15.50),
(109, 'Victor', 'D01', 20.50);

insert into assignment values
('PC010', 100),
('PC010', 101),
('PC010', 102),
('PC011', 105),
('PC011', 103),
('PC011', 104), 
('PC012', 315),
('PC012', 218),
('PC012', 109); 

insert into department values
('D01', 'IT'),
('D02', 'Testing'),
('D03', 'Database');
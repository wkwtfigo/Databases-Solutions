explain analyze select *
from Ticket_flights
where ticket_no like '00054343%';

-- Execution Time: 277.634 ms

create index ticket_no_idx on Ticket_flights (ticket_no)
	where ticket_no like '00054343%';

-- Execution Time: 205.923 ms
explain select *
from Ticket_flights
where ticket_no like '00054343%'

-- 37781.81

create index ticket_no_idx on Ticket_flights (ticket_no)
	where ticket_no like '00054343%';

-- 20962.16
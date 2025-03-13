explain analyze select f.flight_no
from tickets t, ticket_flights tf, flights f
where t.ticket_no = tf.ticket_no and tf.flight_id = f.flight_id and t.passenger_name like 'M%';

-- Execution Time: 662.671 ms

create index passenger_name_idx on tickets (passenger_name)
	where passenger_name like 'M%';

-- Execution Time: 549.499 ms (the result is not constant)
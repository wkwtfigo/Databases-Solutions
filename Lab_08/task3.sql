explain analyze select f.flight_no
from tickets t, ticket_flights tf, flights f
where t.ticket_no = tf.ticket_no and tf.flight_id = f.flight_id and t.passenger_name like 'M%';

-- Execution Time: 662.671 ms

create index passenger_name_idx on tickets (passenger_name)
	where passenger_name like 'M%';

-- Execution Time: 549.499 ms (the result is not constant)
-- using gin gives the same result as a btree

-- index of (ticket_no, flight_id) in ticket_flights gives execution time worse than the first version
-- index of (flight_id) is also not useful
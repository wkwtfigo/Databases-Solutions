explain select f.flight_no
from tickets t
join ticket_flights tf on t.ticket_no = tf.ticket_no
join flights f on tf.flight_id = f.flight_id
where t.passenger_name like 'M%';

-- 64794.12

create index passenger_name_idx on tickets (passenger_name)
	where passenger_name like 'M%';

-- 61170.03
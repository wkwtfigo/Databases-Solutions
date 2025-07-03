create or replace function retreiveFlights(p_start INT, p_end INT) -- p_start is not including
returns table (
	flight_id INT,
	flight_no character,
	scheduled_departure timestamp with time zone,
	scheduled_arrival timestamp with time zone
) as $$
begin
	if p_start < 0 or p_end < 0 then
		raise exception 'Start and end parameters must be non-negative.';
	end if;

	return query
	select f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival
	from flights f
	order by f.flight_id
	offset p_start - 1 -- include p_start
	limit p_end - p_start;
end;
$$ language plpgsql;

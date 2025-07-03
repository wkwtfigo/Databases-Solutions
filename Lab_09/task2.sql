create or replace function retreiveFlightsPage(pageSize INT, pageNumber INT)
returns table (
	flight_id INT,
	flight_no character,
	scheduled_departure timestamp with time zone,
	scheduled_arrival timestamp with time zone
) as $$
begin
	if pageSize < 0 or pageNumber < 0 then
		raise exception 'Page size and number must be non-negative.';
	end if;

	return query
	select f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival
	from flights f
	order by f.flight_id
	offset pageSize * (pageNumber - 1)
	limit pageSize;
end;
$$ language plpgsql;
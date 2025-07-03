create or replace function get_airport_addresses()
returns table (
    airport_code character, 
    lat NUMERIC, 
    lon NUMERIC
) AS $$
begin
    return query
    select a.airport_code, (a.coordinates[0])::NUMERIC, (a.coordinates[1])::NUMERIC
    from airports_data a
    where (a.coordinates[0])::NUMERIC BETWEEN 35 AND 50
      and (a.coordinates[1])::NUMERIC BETWEEN 35 AND 50;
end;
$$ LANGUAGE plpgsql;
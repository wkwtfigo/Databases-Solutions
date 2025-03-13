SET search_path TO bookings;

explain analyze select t.passenger_name, t.book_ref, t.ticket_no, b.book_date
from tickets t, bookings b
where t.book_ref = b.book_ref 
	and t.book_ref like 'B%' 
	and t.ticket_no like '000543';

-- Execution Time: 0.148 ms

create index book_ref_idx on bookings (book_ref);

-- Execution Time: 0.059 ms

create index book_ref_book_date_idx on bookings (book_ref, book_date);

-- Execution Time: 0.170 ms
-- book date does not participate in WHERE statement
-- we already have an index for book_ref, so the search didn't get any faster
SET search_path TO bookings;

explain select t.passenger_name, t.book_ref, t.ticket_no, b.book_date
from tickets t, bookings b
where t.book_ref = b.book_ref 
	and t.book_ref like 'B%' 
	and t.ticket_no like '000543';

-- Query complete 00:00:00.054

create index book_ref_idx on bookings (book_ref);

-- Query complete 00:00:00.042

create index book_ref_book_date_idx on bookings (book_ref, book_date);

-- Query complete 00:00:00.043
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100) NOT NULL,
    balance NUMERIC(15,2) NOT NULL CHECK (balance >= 0),
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'EUR', 'RUB'))
);

INSERT INTO accounts (owner_name, balance, currency) VALUES
('John Doe', 1500.00, 'USD'),
('Alice Smith', 1300.00, 'EUR'),
('Ivan Petrov', 100000.00, 'RUB');

commit;

create table conversion_rates (
	id serial primary key,
	currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
	currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
	conversion_rate NUMERIC(10,6) NOT NULL CHECK (conversion_rate > 0),
	unique (currency_from, currency_to)
)

INSERT INTO conversion_rates (currency_from, currency_to, conversion_rate) VALUES
('USD', 'EUR', 0.92),
('EUR', 'USD', 1.09),
('USD', 'RUB', 75.00),
('RUB', 'USD', 0.013),
('EUR', 'RUB', 81.00),
('RUB', 'EUR', 0.012);

commit;

create table transactions (
	id serial primary key,
	account_from int not null,
	account_to int not null,
	amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
	currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
	currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
	conversion_rate NUMERIC(10,6) NOT NULL,
	converted_amount numeric(15,2) not null,
	transaction_time TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (account_from) REFERENCES accounts(id),
    FOREIGN KEY (account_to) REFERENCES accounts(id)
)

commit;

create or replace function perform_transaction (
	account_from int,
	account_to int,
	amount numeric,
	currency_from varchar(3),
	currency_to varchar(3)
) returns void is $$
declare
	conversion_rate numeric(10, 6);
	converted_amount numeric(15, 2);
begin
	if currency_from = currency_to then
		converted_amount := amount;
	else
		select c.conversion_rate into conversion_rate
		from conversion_rates c
		where c.currency_from = currency_from and c.currency_to = currency_to;
	
		if conversion_rate is null then
			raise exception 'Conversion rate not found for % and %', currency_from, currency_to;
		end if;
	
		converted_amount := amount * conversion_rate
	end if;

	begin
		update accounts
		set balance = balance - amount
		where id = account_from;

		update accounts
		set balance = balance + converted_amount
		where id = account_to;

		insert into transactions (account_from, account_to, amount, currency_from, currency_to, conversion_rate, converted_amount)
        values (sender_id, receiver_id, amount, from_currency, to_currency, COALESCE(conversion_rate, 1), converted_amount);
	end;
end;
$$ language plpgsql;
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
	currency_from_param varchar(3),
	currency_to_param varchar(3)
) returns void as $$
declare
	conversion_rate_param numeric(10, 6);
	converted_amount numeric(15, 2);
begin
	-- accounts have the same currency
	if currency_from_param = currency_to_param then
		converted_amount := amount;
	else
		select c.conversion_rate into conversion_rate_param
		from conversion_rates c
		where c.currency_from = currency_from_param and c.currency_to = currency_to_param;

		-- conversion rate between accounts currencies is not found
		if conversion_rate_param is null then
			raise exception 'Conversion rate not found for % and %', currency_from_param, currency_to_param;
		end if;
	
		converted_amount := amount * conversion_rate_param;
	end if;

	begin
		update accounts
		set balance = balance - amount
		where id = account_from;

		update accounts
		set balance = balance + converted_amount
		where id = account_to;

		-- add new transaction into the table
		insert into transactions (account_from, account_to, amount, currency_from, currency_to, conversion_rate, converted_amount)
        values (account_from, account_to, amount, currency_from_param, currency_to_param, COALESCE(conversion_rate_param, 1), converted_amount);
	end;
end;
$$ language plpgsql;

create or replace function rollback_last_transaction() returns void as $$
declare 
	last_tr transactions%ROWTYPE;
begin
	select * into last_tr from transactions order by transaction_time desc limit 1;

	if not found then
		raise exception 'No transactions found to rollback';
	end if;

	update accounts
	set balance = balance + last_tr.amount
	where id = last_tr.account_from;

	update accounts
	set balance = balance - last_tr.converted_amount
	where id = last_tr.account_to;

	delete from transactions where id = last_tr.id;
end;
$$ language plpgsql;

alter table accounts 
add column bank_country VARCHAR(10) CHECK (bank_country IN ('USA', 'Germany', 'Russia', 'NULL'));

update accounts 
set bank_country = 'USA' 
where id = 1;

update accounts 
set bank_country = 'Germany' 
where id = 2;

update accounts 
set bank_country = 'Russia' 
where id = 3;

-- fees account
insert into accounts (owner_name, balance, currency, bank_country)
values ('Fees Account', 0, 'RUB', 'Russia');

create or replace function perform_transaction_with_fee (
	account_from int,
	account_to int,
	amount numeric,
	currency_from_param varchar(3),
	currency_to_param varchar(3)
) returns void as $$
declare
	country_from varchar(15);
	country_to varchar(15);
	conversion_rate_param numeric(10, 6);
	converted_amount numeric(15, 2);
	fee numeric(15,2) := 0;
	fee_currency varchar(3);
	fee_rub numeric(15,2);
begin
	select bank_country into country_from from accounts where id = account_from;
	select bank_country into country_to from accounts where id = account_to;

    -- i assume that we cannnot have account with non government currency
	if country_from <> country_to then
		if country_from = 'USA' then
			fee := 25;
			fee_currency := 'USD';
		elsif country_from = 'Germany' then
			fee := 20;
			fee_currency := 'EUR';
		elsif country_from = 'Russia' then
			fee := 1500;
			fee_currency := 'RUB';
		end if;
	end if;

	if currency_from_param = currency_to_param then
		converted_amount := amount;
	else
		select c.conversion_rate into conversion_rate_param
		from conversion_rates c
		where c.currency_from = currency_from_param and c.currency_to = currency_to_param;

		if conversion_rate_param IS NULL THEN
            RAISE EXCEPTION 'Conversion rate not found for % to %', currency_from_param, currency_to_param;
        end if;

		converted_amount := (amount - fee) * conversion_rate_param;
	end if;

	update accounts
	set balance = balance - amount
	where id = account_from;

	update accounts
	set balance = balance + converted_amount
	where id = account_to;

	if fee > 0 then
		if fee_currency = 'RUB' then
			fee_rub := fee;
		else
			select c.conversion_rate into conversion_rate_param
			from conversion_rates c
			where c.currency_from = currency_from_param and c.currency_to = 'RUB';
	
			if conversion_rate_param IS NULL THEN
	        	RAISE EXCEPTION 'Conversion rate not found for % to RUB', fee_currency;
	        end if; 
	
			fee_rub := fee * conversion_rate_param;
		end if;

		update accounts
		set balance = balance + fee_rub
		where id = 4;
	end if;

	insert into transactions (account_from, account_to, amount, currency_from, currency_to, conversion_rate, converted_amount)
   	values (account_from, account_to, amount, currency_from_param, currency_to_param, COALESCE(conversion_rate_param, 1), converted_amount);
end;
$$ language plpgsql;

create or replace function rollbaack_last_transaction_with_fee() returns void as $$
declare
	last_tr transactions%ROWTYPE;
	fee_rub numeric(15,2);
begin
	select * into last_tr from transactions order by transaction_time desc limit 1;

	if not found then
        raise exception 'No transactions found to rollback';
    end if;

	update accounts
    set balance = balance + last_tr.amount + 
        case
            when last_tr.currency_from = 'USD' then 25 * (select conversion_rate from conversion_rates where currency_from = 'USD' and currency_to = 'RUB')
            when last_tr.currency_from = 'EUR' then 20 * (select conversion_rate from conversion_rates where currency_from = 'EUR' and currency_to = 'RUB')
            when last_tr.currency_from = 'RUB' then 1500
            else 0
        end
    where id = last_tr.account_from;

	update accounts
    set balance = balance - last_tr.converted_amount
    where id = last_tr.account_to;

	if last_tr.currency_from <> last_tr.currency_to then
        if last_tr.currency_from = 'USD' then
            fee_rub := 25 * (select conversion_rate from conversion_rates where currency_from = 'USD' and currency_to = 'RUB');
        elsif last_tr.currency_from = 'EUR' then
            fee_rub := 20 * (select conversion_rate from conversion_rates where currency_from = 'EUR' and currency_to = 'RUB');
        elsif last_tr.currency_from = 'RUB' then
            fee_rub := 1500;
        end if;

        update accounts
        set balance = balance - fee_rub
        where id = 4;
    end if;

	delete from transactions where id = last_tr.id;
end;
$$ language plpgsql;

select * from accounts;

begin
	-- T1: Account 1 (USD) sends 200 USD to Account 2 (EUR)
	select perform_transaction(1, 2, 200, 'USD', 'EUR');
	
	-- T2: Account 2 (EUR) sends 300 EUR to Account 3 (RUB)
	select perform_transaction(2, 3, 300, 'EUR', 'RUB');
	
	-- T3: Account 3 (RUB) sends 1000 RUB to Account 1 (USD)
	select perform_transaction(3, 1, 1000, 'RUB', 'USD');

BEGIN;
	-- T1: Account 1 (USA, USD) sends 200 USD to Account 2 (Germany, EUR)
	SELECT perform_transaction_with_fee(1, 2, 200, 'USD', 'EUR');

	-- T2: Account 2 (Germany, EUR) sends 300 EUR to Account 3 (Russia, RUB)
	SELECT perform_transaction_with_fee(2, 3, 300, 'EUR', 'RUB');

	-- T3: Account 3 (Russia, RUB) sends 1000 RUB to Account 1 (USA, USD)
	SELECT perform_transaction_with_fee(3, 1, 1000, 'RUB', 'USD');

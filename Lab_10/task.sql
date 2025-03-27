-- TASK 1: create table accounts
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100) NOT NULL,
    balance NUMERIC(15,2) NOT NULL CHECK (balance >= 0),
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'EUR', 'RUB'))
);

-- insert into table accounts 3 accounts
INSERT INTO accounts (owner_name, balance, currency) VALUES
('John Doe', 1500.00, 'USD'),
('Alice Smith', 1300.00, 'EUR'),
('Ivan Petrov', 100000.00, 'RUB');

select * from accounts;

-- TASK 2: create table of currency conversion rates
create table conversion_rates (
	id serial primary key,
	currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
	currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
	conversion_rate NUMERIC(10,6) NOT NULL CHECK (conversion_rate > 0),
	unique (currency_from, currency_to)
)

-- insert needed data
INSERT INTO conversion_rates (currency_from, currency_to, conversion_rate) VALUES
('USD', 'EUR', 0.92),
('EUR', 'USD', 1.09),
('USD', 'RUB', 75.00),
('RUB', 'USD', 0.013),
('EUR', 'RUB', 81.00),
('RUB', 'EUR', 0.012);

select * from conversion_rates;

-- TASK 3: create table for transactions
-- include e Currency From, Currency To, and Conversion Rate
-- populate the table with necessary conversion rates between USD, EUR, and RUB
create table transactions (
	id serial primary key,
	account_from int not null, -- sender
	account_to int not null, -- receiver
	amount NUMERIC(15,2) NOT NULL CHECK (amount > 0), -- amount in sender's currency
	currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
	currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
	conversion_rate NUMERIC(10,6) NOT NULL, -- from conversion_rates
	converted_amount numeric(15,2) not null,
	transaction_time TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (account_from) REFERENCES accounts(id),
    FOREIGN KEY (account_to) REFERENCES accounts(id)
)

-- TASK 3: return the updated balance for all accounts
create or replace function perform_transaction (
	account_from int,
	account_to int,
	amount numeric,
	currency_from_param varchar(3),
	currency_to_param varchar(3)
) returns table (
	account_id_from int,
	updated_balance_from numeric,
	account_id_to int,
	updated_balance_to numeric
) as $$
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

	update accounts
	set balance = balance - amount
	where id = account_from
	returning id, balance into account_id_from, updated_balance_from;

	update accounts
	set balance = balance + converted_amount
	where id = account_to
	returning id, balance into account_id_to, updated_balance_to;

	-- add new transaction into the table
	insert into transactions (account_from, account_to, amount, currency_from, currency_to, conversion_rate, converted_amount)
    values (account_from, account_to, amount, currency_from_param, currency_to_param, COALESCE(conversion_rate_param, 1), converted_amount);

	return query
	select account_id_from, updated_balance_from, account_id_to, updated_balance_to;
end;
$$ language plpgsql;

-- T1: Account 1 (USD) sends 200 USD to Account 2 (EUR)
select * from perform_transaction(1, 2, 200, 'USD', 'EUR');
	
-- T2: Account 2 (EUR) sends 300 EUR to Account 3 (RUB)
select * from perform_transaction(2, 3, 300, 'EUR', 'RUB');
	
-- T3: Account 3 (RUB) sends 1000 RUB to Account 1 (USD)
select * from perform_transaction(3, 1, 1000, 'RUB', 'USD');

-- TASK 3: rollback mechanism for the last transaction
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


-- TASK 4: add a field for BankCountry (options: USA, Germany, Russia)
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

-- TASK 4: fees should be stored in a new record in accounts table
insert into accounts (owner_name, balance, currency, bank_country)
values ('Fees Account', 0, 'RUB', 'Russia');

-- TASK 5: international transactions have a variable fee based on the sander's country
create or replace function perform_transaction_with_fee (
	account_from int,
	account_to int,
	amount numeric,
	currency_from_param varchar(3),
	currency_to_param varchar(3)
) returns table (
	account_id_from int,
	updated_balance_from numeric,
	account_id_to int,
	updated_balance_to numeric,
	fees_collected numeric
) as $$
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
	where id = account_from
	returning id, balance into account_id_from, updated_balance_from;

	update accounts
	set balance = balance + converted_amount
	where id = account_to
	returning id, balance into account_id_to, updated_balance_to;

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
		where id = 4
		returning balance into fees_collected;
	end if;

	insert into transactions (account_from, account_to, amount, currency_from, currency_to, conversion_rate, converted_amount)
   	values (account_from, account_to, amount, currency_from_param, currency_to_param, COALESCE(conversion_rate_param, 1), converted_amount);

	return query
	select account_id_from, updated_balance_from, account_id_to, updated_balance_to, fees_collected;
end;
$$ language plpgsql;

-- T1: Account 1 (USA, USD) sends 200 USD to Account 2 (Germany, EUR)
select * from perform_transaction_with_fee(1, 2, 200, 'USD', 'EUR');

-- T2: Account 2 (Germany, EUR) sends 300 EUR to Account 3 (Russia, RUB)
select * from perform_transaction_with_fee(2, 3, 300, 'EUR', 'RUB');

-- T3: Account 3 (Russia, RUB) sends 1000 RUB to Account 1 (USA, USD)
select * from perform_transaction_with_fee(3, 1, 1000, 'RUB', 'USD');

-- TASK 6: rollback mechanism
create or replace function rollback_last_transaction_with_fee() returns void as $$
declare
	last_tr transactions%ROWTYPE;
	fee_rub numeric(15,2);
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
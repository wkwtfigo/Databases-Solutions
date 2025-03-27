## Lab 10
### Task 1: Create Table `accounts`

We begin by creating the `accounts` table to store information about accounts, including the owner's name, balance, and currency.

```sql
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100) NOT NULL,
    balance NUMERIC(15,2) NOT NULL CHECK (balance >= 0),
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'EUR', 'RUB'))
);
```

```sql
INSERT INTO accounts (owner_name, balance, currency) VALUES
('John Doe', 1500.00, 'USD'),
('Alice Smith', 1300.00, 'EUR'),
('Ivan Petrov', 100000.00, 'RUB');
```

| id | owner_name  | balance    | currency |
|----|--------------------------|----------|-----------|
| 1  | John Doe    | 1500.00    | USD      |
| 2  | Alice Smith | 1300.00    | EUR      |
| 3  | Ivan Petrov | 1000000.00 | RUB      |

### Task 2: Create table `conversion_rates`

We create a `conversion_rates` table to store currency conversion rates between different currencies (USD, EUR, and RUB).

```sql
CREATE TABLE conversion_rates (
    id SERIAL PRIMARY KEY,
    currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
    currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
    conversion_rate NUMERIC(10,6) NOT NULL CHECK (conversion_rate > 0),
    UNIQUE (currency_from, currency_to)
);
```

```sql
INSERT INTO conversion_rates (currency_from, currency_to, conversion_rate) VALUES
('USD', 'EUR', 0.92),
('EUR', 'USD', 1.09),
('USD', 'RUB', 75.00),
('RUB', 'USD', 0.013),
('EUR', 'RUB', 81.00),
('RUB', 'EUR', 0.012);
```

| id | currency_from | currency_to | conversion_rate |
|----|--------------------------|----------|-----------|
| 1  | USD | EUR | 0.920000 |
| 2  | EUR | USD | 1.090000 |
| 3  | USD | RUB | 75.000000 |
| 4  | RUB | USD | 0.013000 |
| 5  | EUR | RUB | 81.000000 |
| 6  | RUB | EUR | 0.012000 |

### Task 3: Create table `transactions` and Define `perform_transaction` function

We create a `transactions` table to log each transaction, including the sender, receiver, the amount, currency used, conversion rate, and the converted amount.

```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    account_from INT NOT NULL, -- sender
    account_to INT NOT NULL, -- receiver
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0), -- amount in sender's currency
    currency_from VARCHAR(3) NOT NULL CHECK (currency_from IN ('USD', 'EUR', 'RUB')),
    currency_to VARCHAR(3) NOT NULL CHECK (currency_to IN ('USD', 'EUR', 'RUB')),
    conversion_rate NUMERIC(10,6) NOT NULL, -- from conversion_rates
    converted_amount NUMERIC(15,2) NOT NULL,
    transaction_time TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (account_from) REFERENCES accounts(id),
    FOREIGN KEY (account_to) REFERENCES accounts(id)
);
```

`perform_transaction` function updates the balance of the sender and receiver accounts, based on the conversion rate, and logs the transaction.

```sql
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
```

#### Example

```sql
-- T1: Account 1 (USD) sends 200 USD to Account 2 (EUR)
select * from perform_transaction(1, 2, 200, 'USD', 'EUR');
```
Returned values:
| id | account_id_from | updated_balance_from | account_id_to | updated_balance_to |
|----|--------------------------|----------|-----------|-----|
| 1  | 1 | 1300 | 2 | 1484 |

Table `transactions`:
| id | account_from | account_to | amount | currency_from | currency_to | conversion_rate | converted_amount | transaction_time|
|----|---------------------------|--------|-----------|-----|------|------|-------|------|
| 1  | 1            | 2          | 200.00 | USD | EUR | 0.920000 | 184 | 2025-03-27 14:13:10.69264 |

We also create a rollback mechanism for the last transaction.

```sql
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
```

### Task 4: Add bank country and fees account

We add a column for `bank_country` in the `accounts` table and populate it for the existing accounts.

```sql
ALTER TABLE accounts 
ADD COLUMN bank_country VARCHAR(10) CHECK (bank_country IN ('USA', 'Germany', 'Russia', 'NULL'));

UPDATE accounts 
SET bank_country = 'USA' 
WHERE id = 1;

UPDATE accounts 
SET bank_country = 'Germany' 
WHERE id = 2;

UPDATE accounts 
SET bank_country = 'Russia' 
WHERE id = 3;
```

### Task 5:

We insert a new account for collected fees.

```sql
INSERT INTO accounts (owner_name, balance, currency, bank_country)
VALUES ('Fees Account', 0, 'RUB', 'Russia');
```
Variable fees do not have a separate table.

### Task 6

We create the `perform_transaction_with_fee` function, which calculates a variable fee based on the sender's country. The fee is collected into a separate account.

```sql
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
```

We also create a rollback mechanism for the last transaction.

```sql
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
```
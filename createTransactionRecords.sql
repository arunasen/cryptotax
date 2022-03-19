CREATE DEFINER=`root`@`localhost` PROCEDURE `createTransactionRecords`()
BEGIN    
    #add coinbase deposits
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'coinbase', 'deposit', amount, `amount/balance unit`, 
	str_to_date(replace(replace(trade_time, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date
	from coinbaseprotransactions
	where type = 'deposit';

	#add coinbase withdrawals
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'coinbase', 'withdrawal', abs(amount), `amount/balance unit`, 
	str_to_date(replace(replace(trade_time, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date
	from coinbaseprotransactions
	where type = 'withdrawal';
    
  #add binance deposits, none taxable for 2021
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'binance', 'deposit', realized_amount_for_primary_asset_in_USD_Value, primary_asset, time 
	from binanceTransactions
	where operation in ('USD Deposit', 'Crypto Deposit');
	
  #add binance withdrawals, non-taxable
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'binance', 'withdrawal', abs(realized_amount_for_primary_asset), primary_asset, time 
	from binanceTransactions
	where operation in ('Withdrawal', 'Crypto Withdrawal');

	#add binance income, taxable
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'binance', 'income', realized_amount_for_primary_asset, primary_asset, time,  
	realized_amount_for_primary_asset_in_usd_value, 0.0, operation
	from binanceTransactions
	where operation in ('Staking Rewards');
    
  #add blockfi transactions for stablecoin
  insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'blockfi', 'income', amount, cryptocurrency, confirmed_at, amount, 0.0, transaction_type 
	from blockfitransactions
	where transaction_type in ('Interest Payment',
	'Cc Rewards Redemption',
	'Cc Trading Rebate',
	'Bonus Payment')
	and cryptocurrency = 'GUSD';

	#add blockfi transactions for BTC
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'blockfi', 'income', b.amount, b.cryptocurrency, b.confirmed_at, b.amount * d.price, 0.0, b.transaction_type 
	from blockfitransactions b
	join btcusdhistoricaldata d
	on date(b.confirmed_at) = date(d.date)
	where transaction_type in ('Interest Payment',
	'Cc Rewards Redemption',
	'Cc Trading Rebate',
	'Bonus Payment')
	and cryptocurrency = 'BTC';
    
  #add blockfi transactions for deposits
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'blockfi', 'deposit', abs(amount), 'USD', confirmed_at 
	from blockfitransactions
	where transaction_type in ('Ach Deposit')
	or cryptocurrency = 'USD';
    
  #add cash app transactions (withdrawal only for 2021)
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'cash app', 'withdrawal', abs(asset_amount), asset_type, str_to_date(replace(Date, 'EST', ''), '%Y-%m-%d %H:%i:%s')
	from cashapptransactions
	where `Transaction Type` = 'Bitcoin Withdrawal';
    
  #add nexo income records (taxable)
  insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'nexo', 'income', abs(amount), currency, date_time, replace(usd_equivalent, '$', ''), 0.0, type
	from nexotransactions
	where type in ('Interest', 'ReferralBonus');
    
  #add nexo deposit records
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'nexo',  'deposit', amount, currency, date_time
	from nexotransactions
	where type in ('Deposit');
    
  #add kraken transactions (no taxable transactions for 2021)
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'kraken', type, abs(amount), replace(replace(asset, 'XXBT', 'BTC'), 'ZUSD', 'USD'), time
	from krakentransactions
	where type in ('deposit', 'withdrawal')
	and txid != '';
    
   #add kinesis KAG income
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'kinesis', 'income', t.buy, t.buy_cur, t.datetime, t.buy, 0.0, t.comment
	from kinesistransactions t
	join xagusdhistoricaldata s on t.buy_cur = 'KAG' and date(s.datetime) =
	(select
	date(s.datetime)
	from xagusdhistoricaldata s
	where date(s.datetime) >= date(t.datetime)
	limit 1)
	where t.type = 'Income';

	#add kinesis KAU income, 28.3495 is for oz to gram conversion
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'kinesis', 'income', t.buy, t.buy_cur, t.datetime, g.price/28.3495*buy, 0.0, comment
	from kinesistransactions t
	join xauusdhistoricaldata g on t.buy_cur = 'KAU' and date(g.datetime) = 
	(select
	date(g.datetime)
	from xauusdhistoricaldata g
	where date(g.datetime) >= date(t.datetime)
	limit 1)
	where t.type = 'Income';

	#add kinesis deposits
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'kinesis', 'deposit', buy, buy_cur, datetime from kinesistransactions t
	where type in ('Deposit');

	#add kinesis withdrawals
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'kinesis', 'withdrawal', sell-fee, buy_cur, datetime from kinesistransactions t
	where type in ('Withdrawal')
	and sell_cur = fee_cur;
    
  #add hoo transactions
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'hoo', replace(replace(transaction_type, 'Deposit', 'deposit'), 'Withdraw', 'withdrawal'), amount, currency, time
	from hootransactions
	where transaction_type in ('Deposit', 'Withdraw');
    
	#add coinbase (not pro) withdrawals (non taxable)
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'coinbase', 'withdrawal',`Quantity Disposed`, `Asset Disposed (Sold, Sent, etc)`,
	str_to_date(replace(replace(`Date & time`, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date 
	from coinbaseTransactions
	where `Transaction Type` = 'Withdrawal';

	#add coinbase (not pro) deposits (non taxable)
	insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'coinbase', 'deposit',`Quantity Acquired (Bought, Received, etc)`, `Asset Acquired`,
	str_to_date(replace(replace(`Date & time`, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date 
	from coinbaseTransactions
	where `Transaction Type` = 'Deposit';

	#add coinbase (not pro) income--taxable for 2021
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used, comment)
	select 'coinbase', 'income',`Quantity Acquired (Bought, Received, etc)`, `Asset Acquired`,
	str_to_date(replace(replace(`Date & time`, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date,
	`Cost Basis (incl. fees paid) (USD)`, 0.0, `Transaction Type` 
	from coinbaseTransactions
	where `Transaction Type` = 'Reward';
    
  #add kucoin transactions
  insert into transactions (exchange, transaction_type, asset_amount, asset, date)
	select 'kucoin', LOWER(type), `Amount(Fee included)`,Coin, Time
	from kucoinTransactions
	where type in ('Deposit', 'Withdrawal');
END

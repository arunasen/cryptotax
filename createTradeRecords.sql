CREATE DEFINER=`root`@`localhost` PROCEDURE `createTradeRecords`()
BEGIN
	#clean out the trades table
	#truncate transactions;

	#kraken buys
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kraken', 'buy', base.amount, 'BTC', base.time, abs(quote.amount)+quote.fee+5, 0.0
	from krakenTransactions base, krakenTransactions quote
	where 
	((quote.type = 'trade'
	and base.type = 'trade')
	or (base.type = 'receive' and quote.type = 'spend'))
	and quote.amount < 0
	and base.amount > 0
	and base.refid = quote.refid
	and quote.asset = 'ZUSD'
	and base.asset = 'XXBT';

	#kucoin buys
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kucoin', 'buy', size, substring_index(symbol, '-', 1), tradeCreatedAt, funds+fee, 0.0 
	from kucoinTrades
	where side = 'buy';

	#kucoin sells
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kucoin', 'sell', size, substring_index(symbol, '-', 1), tradeCreatedAt, funds-fee, 0.0 
	from kucoinTrades
	where side = 'sell';

	#kinesis sells where fee is in base currency
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'sell', amount+fee, amount_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	Trade_Value_in_USD, 0.0
	 from kinesisTrades
	where transaction_type = 'sell'
	and amount_currency = fee_currency;

	#kinesis sells where fee is in quote currency USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'sell', amount, amount_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	total-fee, 0.0
	 from kinesisTrades
	where transaction_type = 'sell'
	and trade_price_currency = fee_currency
	and trade_price_currency = 'USD';

	#kinesis sells where fee is in quote currency not USD-sell to USD first
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'sell', amount, amount_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	Trade_Value_in_USD, 0.0
	 from kinesisTrades
	where transaction_type = 'sell'
	and trade_price_currency = fee_currency
	and trade_price_currency != 'USD';

	#kinesis sells where fee is in quote currency not USD-buy quote currency using USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'buy', Total-Fee, Trade_Price_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	Trade_Value_in_USD, 0.0
	 from kinesisTrades
	where transaction_type = 'sell'
	and trade_price_currency = fee_currency
	and trade_price_currency != 'USD';

	#kinesis buys where fee is in quote currency
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'buy', amount, amount_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	Total+Fee, 0.0
	 from kinesisTrades
	where transaction_type = 'buy'
	and trade_price_currency = fee_currency;

	#kinesis buys where fee is in base currency
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'kinesis', 'buy', amount-fee, amount_currency, str_to_date(replace(DateTime, ' UTC', ''), '%Y-%m-%d %H:%i:%s'),
	Total, 0.0
	 from kinesisTrades
	where transaction_type = 'buy'
	and amount_currency = fee_currency;

	#hoo exchange buys
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'hoo', 'buy',  volume, substring_index(pair, '-', 1), time, amount+fee, 0.0 
	from hootrades
	where direction = 'BUY';

	#hoo exchange sells
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'hoo', 'sell',  volume, substring_index(pair, '-', 1), time, amount-fee, 0.0 
	from hootrades
	where direction = 'SELL';

	#cash app--no sells for 2021
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'cash app', 'buy', Asset_amount, Asset_type, str_to_date(replace(Date, 'EST', ''), '%Y-%m-%d %H:%i:%s'), 
	replace(Amount, '-$', '') + replace(Fee, '-$', ''), 0.0
	from cashAppTransactions 
	where `Transaction Type` = 'Bitcoin Buy';
	 
	#binance buys using USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'buy', Realized_Amount_For_Base_Asset, Base_Asset, time,
	Realized_Amount_For_Quote_Asset_In_USD_Value+Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0  
	from binancetransactions
	where Quote_Asset in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Buy';

	#binance sells using USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'sell', Realized_Amount_For_Base_Asset, Base_Asset, time,
	Realized_Amount_For_Quote_Asset_In_USD_Value-Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0  
	from binancetransactions
	where Quote_Asset in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Sell';

	#binance buys where quote is not USD; first sell quote for USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'sell', Realized_Amount_For_Quote_Asset, Quote_Asset, time,
	Realized_Amount_For_Quote_Asset_In_USD_Value-Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0
	from binancetransactions
	where Quote_Asset not in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Buy';

	#binance buys where quote is not USD; buy base using USD value from sell of quote
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'buy', Realized_Amount_For_Base_Asset, Base_Asset, time,
	Realized_Amount_For_Quote_Asset_In_USD_Value-Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0
	from binancetransactions
	where Quote_Asset not in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Buy';

	#binance sells where quote is not USD; first sell base for USD
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'sell', Realized_Amount_For_Base_Asset, Base_Asset, time,
	Realized_Amount_For_Base_Asset_In_USD_Value-Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0
	from binancetransactions
	where Quote_Asset not in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Sell';

	#binance sells where quote is not USD; buy quote currency using USD value from selling the base
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'binance', 'buy', Realized_Amount_For_Quote_Asset, Quote_Asset, time,
	Realized_Amount_For_Base_Asset_In_USD_Value-Realized_Amount_For_Fee_Asset_In_USD_Value, 0.0
	from binancetransactions
	where Quote_Asset not in ('USD', 'USDT', 'BUSD', 'USDC') AND Operation = 'Sell';
    
	#blockfi buys (no sells for 2021)
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'blockfi', 'buy', base.Amount, base.Cryptocurrency, base.Confirmed_At, abs(quote.amount), 0.0
	from blockfiTransactions base, blockfiTransactions quote
	where base.Transaction_type in ('Trade', 'Ach Trade')
	and quote.Transaction_type in ('Trade', 'Ach Trade')
	and base.Confirmed_At = quote.Confirmed_At
	and quote.Cryptocurrency in ('USD', 'GUSD')
	and base.Cryptocurrency not in ('USD', 'GUSD');

	#coinbase buys
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'coinbase pro', 'buy' as transaction_type, base.amount as asset_amount, base.`amount/balance unit` as asset,
	str_to_date(replace(replace(base.trade_time, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date , abs(quote.amount + fee.amount) as usd_amount, 0.0
	from coinbaseprotransactions base, coinbaseprotransactions quote, coinbaseprotransactions fee
	where base.type = 'match' and quote.type = 'match' and fee.type = 'fee'
	and base.`trade id` = quote.`trade id`
	and fee.`trade id` = quote.`trade id`
	and base.`amount/balance unit` != 'USD'
	and quote.`amount/balance unit` = 'USD'
	and base.amount > 0;

	#coinbase sells
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'coinbase pro', 'sell' as transaction_type, abs(base.amount) as asset_amount, base.`amount/balance unit` as asset,
	str_to_date(replace(replace(base.trade_time, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date ,
	quote.amount - abs(fee.amount) as usd_amount, 0.0
	from coinbaseprotransactions base, coinbaseprotransactions quote, coinbaseprotransactions fee
	where base.type = 'match' and quote.type = 'match' and fee.type = 'fee'
	and base.`trade id` = quote.`trade id`
	and fee.`trade id` = quote.`trade id`
	and base.`amount/balance unit` != 'USD'
	and quote.`amount/balance unit` = 'USD'
	and base.amount < 0;
    
    #coinbase (not pro) buys 
	insert into transactions (exchange, transaction_type, asset_amount, asset, date, usd_amount, basis_used)
	select 'coinbase', 'buy',`Quantity Acquired (Bought, Received, etc)`,`Asset Acquired`,
	str_to_date(replace(replace(`Date & time`, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s.%f') as date,
	`Cost Basis (incl. fees paid) (USD)`, 0.0 
	from coinbaseTransactions
	where `Transaction Type` = 'Buy';
END

CREATE DEFINER=`root`@`localhost` PROCEDURE `calculateProfitLoss`(
	IN coin VARCHAR(10),
    OUT long_basis DOUBLE,
    OUT long_proceeds DOUBLE,
    OUT short_basis DOUBLE,
    OUT short_proceeds DOUBLE
    )
BEGIN
	DECLARE done INT DEFAULT FALSE;
    DECLARE sell_amount DOUBLE DEFAULT 0.0;
    DECLARE buy_amount DOUBLE DEFAULT 0.0;
    DECLARE updateRowIDBuy INT DEFAULT 0;
    DECLARE updateRowIDSell INT DEFAULT 0;
    DECLARE sell_time DATETIME;
    DECLARE buy_time DATETIME;
    DECLARE usd_remaining_sell DOUBLE DEFAULT 0.0;
    DECLARE usd_remaining_buy DOUBLE DEFAULT 0.0;
    DECLARE usd_used_buy DOUBLE DEFAULT 0.0;
    DECLARE usd_total_buy DOUBLE DEFAULT 0.0;
    DECLARE usd_used_sell DOUBLE DEFAULT 0.0;
    DECLARE percentage_used DOUBLE DEFAULT 0.0;
    DECLARE transaction_category VARCHAR(15) DEFAULT '';
    DECLARE looper INT DEFAULT 0;
    
    #FIFO calculation--First In (oldest buy/income) First Out (oldest sell)
    DECLARE buyCursor CURSOR FOR
	SELECT asset_amount, usd_amount-basis_used as basisUSD, transaction_id, date
	FROM transactions
	WHERE asset = coin
	and transaction_type in ('income', 'buy')
	and basis_used < usd_amount
	ORDER BY date;
    
    DECLARE sellCursor CURSOR FOR
	SELECT asset_amount, usd_amount, transaction_id, date
	FROM transactions
	WHERE asset = coin
	AND transaction_type = 'sell'
	ORDER BY date;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
	SET long_basis = 0.0;
    SET short_basis = 0.0;
    SET long_proceeds = 0.0;
    SET short_proceeds = 0.0;
    SET sell_amount = 0.0;
    SET buy_amount = 0.0;
    
	OPEN buyCursor;
    OPEN sellCursor;
    
	sellingLoop: LOOP
			FETCH sellCursor INTO sell_amount, usd_remaining_sell, updateRowIDSell, sell_time;
			SET usd_used_sell = 0.0;
        IF done THEN
			LEAVE sellingLoop;
		END IF;
        buyingLoop: LOOP
			IF sell_amount = 0.0 THEN #need a new sell order
				LEAVE buyingLoop;
			END IF;
			IF buy_amount = 0.0 THEN #handle remaining buy when a new sell is pulled
				FETCH buyCursor INTO buy_amount, usd_remaining_buy, updateRowIDBuy, buy_time;
                IF done THEN
					LEAVE buyingLoop;
				END IF;
                SET usd_used_buy = 0.0;
                SET usd_total_buy = usd_remaining_buy;
			END IF;
            IF buy_amount >= sell_amount THEN #buy amount more or same as sell amount
				SET percentage_used = sell_amount / buy_amount; #percentage of buy used
                SET usd_used_buy = usd_used_buy + percentage_used * usd_remaining_buy; #partially used, increment via percentage
                
                SET usd_used_sell = usd_used_sell + usd_remaining_sell; #increment by the amount of sell order used directly
                SET buy_amount = buy_amount - sell_amount;

                SET sell_amount = 0.0;
                 #determine whether proceed is long or short.
				IF TIMESTAMPDIFF(DAY, buy_time, sell_time) > 365 THEN
					SET long_basis = long_basis + percentage_used * usd_remaining_buy;
					SET long_proceeds = long_proceeds + usd_remaining_sell;
                    #SET long_proceeds = long_proceeds + usd_used_sell;
				ELSE
					SET short_basis = short_basis + percentage_used * usd_remaining_buy;
					SET short_proceeds = short_proceeds + usd_remaining_sell;
                    #SET short_proceeds = short_proceeds + usd_used_sell;
				END IF;
                SET usd_remaining_sell = 0.0; #zero the sell out
                SET usd_remaining_buy = usd_remaining_buy - percentage_used * usd_remaining_buy; #decrement remaining buy amount

            ELSE #buy amount less than sell amount
				SET percentage_used =  buy_amount / sell_amount; #percentage of sell used
                SET usd_used_buy = usd_used_buy + usd_remaining_buy; #fully used, increment via remainder
                SET usd_used_sell = usd_used_sell + percentage_used * usd_remaining_sell; #increment via percentage of sell used
                
                SET sell_amount = sell_amount - buy_amount;
                
                SET buy_amount = 0.0;
                #insert into testing values (updateRowIDSell, usd_remaining_sell);
                IF TIMESTAMPDIFF(DAY, buy_time, sell_time) > 365 THEN
					#SET long_basis = long_basis + usd_used_buy;
					SET long_basis = long_basis + usd_remaining_buy;
                    SET long_proceeds =  long_proceeds + percentage_used * usd_remaining_sell;
				ELSE
					#SET short_basis = short_basis + usd_used_buy;
					SET short_basis = short_basis + usd_remaining_buy;
                    SET short_proceeds =  short_proceeds + percentage_used * usd_remaining_sell;
				END IF;
                SET usd_remaining_sell = usd_remaining_sell - percentage_used * usd_remaining_sell; #reduce remaining sell by amount used
                SET usd_remaining_buy = 0.0; #zero the buy out
			END IF;
            
			#update the buys to show basis was consumed
			UPDATE transactions
			SET basis_used = usd_used_buy
			WHERE transaction_id = updateRowIDBuy;

		END LOOP buyingLoop;
        
		#update the basis amount of sells to -1 to show they are met
		UPDATE transactions
		SET basis_used = -1
		WHERE transaction_id = updateRowIDSell;
        
        IF done THEN
			#insert into testing values(updateRowIDBuy, transaction_category, 'message', 0, 'leaving sell loop due to lack of buy data', CURRENT_TIMESTAMP(), coin);
			LEAVE sellingLoop;
		END IF;
        
	END LOOP sellingLoop;
	CLOSE buyCursor;
    CLOSE sellCursor;
END

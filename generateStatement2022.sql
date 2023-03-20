CREATE DEFINER=`root`@`localhost` PROCEDURE `generateStatement`(
IN startDate DATETIME,
IN endDate DATETIME,
IN termName VARCHAR(20),
IN resetBasis TINYINT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
	DECLARE coin VARCHAR(10) DEFAULT 'A';
	DECLARE long_basis DOUBLE DEFAULT 0.0;
    DECLARE long_proceeds DOUBLE DEFAULT 0.0;
	DECLARE short_basis DOUBLE DEFAULT 0.0;
    DECLARE short_proceeds DOUBLE DEFAULT 0.0;
    
	DECLARE coinsCursor CURSOR FOR
	SELECT DISTINCT asset 
	FROM transactions
	WHERE asset NOT IN ('BUSD', 'USD', 'USDT');

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	
    IF resetBasis = 1 THEN
		update transactions
		set basis_used = basis_used_backup, asset_basis_remaining = asset_amount;
	END IF;
		#TRUNCATE summary;
		#TRUNCATE testing;
    delete from summary where term = termName;
	OPEN coinsCursor;

	read_loop: LOOP
		FETCH coinsCursor INTO coin;
        IF done THEN
			LEAVE read_loop;
		END IF;
		CALL calculateProfitLoss(coin, startDate, endDate, long_basis, long_proceeds, short_basis, short_proceeds);
		INSERT INTO summary
		VALUES (coin, long_basis, long_proceeds, short_basis, short_proceeds, 1, termName);
	END LOOP;

CLOSE coinsCursor;
END

CREATE DEFINER=`root`@`localhost` PROCEDURE `generateStatement`()
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

	UPDATE transactions 
	SET basis_used = 0.0;
    TRUNCATE summary;
	TRUNCATE testing;
	OPEN coinsCursor;

	read_loop: LOOP
		FETCH coinsCursor INTO coin;
        IF done THEN
			LEAVE read_loop;
		END IF;
		CALL calculateProfitLoss(coin, long_basis, long_proceeds, short_basis, short_proceeds);
		INSERT INTO summary
		VALUES (coin, long_basis, long_proceeds, short_basis, short_proceeds);
	END LOOP;

CLOSE coinsCursor;
END

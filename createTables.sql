CREATE DEFINER=`root`@`localhost` PROCEDURE `createTables`()
BEGIN
	DROP TABLE IF EXISTS `transactions`;
	CREATE TABLE `transactions` (
	  `transaction_id` int NOT NULL AUTO_INCREMENT,
	  `exchange` varchar(25) DEFAULT NULL,
	  `transaction_type` varchar(15) NOT NULL,
	  `asset_amount` double NOT NULL,
	  `asset` varchar(10) NOT NULL,
	  `date` datetime NOT NULL,
	  `usd_amount` double DEFAULT NULL,
	  `basis_used` double DEFAULT NULL,
	  `comment` varchar(100) DEFAULT NULL,
	  PRIMARY KEY (`transaction_id`)
	) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

	DROP TABLE IF EXISTS `summary`;
	CREATE TABLE `summary` (
	  `coin` varchar(10) NOT NULL,
	  `long_basis` double DEFAULT NULL,
	  `long_proceeds` double DEFAULT NULL,
	  `short_basis` double DEFAULT NULL,
	  `short_proceeds` double DEFAULT NULL,
	  PRIMARY KEY (`coin`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    
	DROP TABLE IF EXISTS `kucointrades`;
	CREATE TABLE `kucointrades` (
	  `tradeCreatedAt` datetime DEFAULT NULL,
	  `orderId` text,
	  `symbol` text,
	  `side` text,
	  `price` double DEFAULT NULL,
	  `size` double DEFAULT NULL,
	  `funds` double DEFAULT NULL,
	  `fee` double DEFAULT NULL,
	  `liquidity` text,
	  `feeCurrency` text,
	  `orderType` text
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
END

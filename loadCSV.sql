TRUNCATE TABLE `kucointrades`;
LOAD DATA LOCAL INFILE 'kucoinTrades.csv' INTO TABLE `kucointrades`
        FIELDS TERMINATED BY ','
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@tradeCreatedAt,
                  `orderId`,
                  `symbol`,
                  `side`,
                  `price`,
                  `size`,
                  `funds`,
                  `fee`,
                  `liquidity`,
                  `feeCurrency`,
                  `orderType`) SET tradeCreatedAt = STR_TO_DATE(@tradeCreatedAt, '%Y/%m/%d %H:%i');

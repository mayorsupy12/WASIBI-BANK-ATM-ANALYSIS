CREATE DATABASE WASIBI_BANK_ATM;
USE WASIBI_BANK_ATM;
select * from transactions;
select * from customers_lookup;
select * from calendar_lookup;
select * from atm_location;
select * from hourlookup;
select * from transaction_type;

CREATE TABLE hourlookup(
    Hour_Key INT PRIMARY KEY ,
    Hour_Start_Time TEXT ,
    Hour_End_Time TEXT 
);

-- CLEANING HOUR_LOOKUP TABLE
-- checking duplicate
select hour_key, count(*)
from hourlookup
group by hour_key
having count(*)>1;

CREATE TABLE atm_location(
    LocationID VARCHAR(50) PRIMARY KEY NOT NULL ,
    LocationName TEXT NOT NULL,
    NoOfATMs INT NOT NULL,
    City TEXT NOT NULL,
   State TEXT NOT NULL,
    Country TEXT NOT NULL
);
-- CLEANING ATM_LOCATION TABLE
-- rename column with special character
alter table atm_location
rename column ï»¿LocationID to LocationID;
-- duplicate
select LocationID, count(*)
from atm_location
group by LocationID
having count(*)>1;

CREATE TABLE calendar_lookup(
   Date  VARCHAR(50) PRIMARY KEY NOT NULL,
    Year INT NOT NULL,
   MonthName TEXT NOT NULL,
    Month INT NOT NULL,
     Quarter TEXT NULL,
   WeekOfYear INT NOT NULL,
    EndOfWeek TEXT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName TEXT NOT NULL,
    IsHoliday INT NOT NULL
);
-- CLEANING CALENDAR_LOOKUP TABLE
-- rename column with special character
alter table calendar_lookup
rename column ï»¿Date to Date;
-- checking duplicate
select Date, count(*)
from calendar_lookup
group by Date
having count(*)>1;
-- check missing values
select Date
from  calendar_lookup
where Date is null;

CREATE TABLE customers_lookup(
    CardholderID VARCHAR(50) PRIMARY KEY NOT NULL,
    FirstName TEXT NULL,
    LastName TEXT NOT NULL,
    Gender TEXT NOT NULL,
    ATMID TEXT NOT NULL,
    BirthDate TEXT NOT NULL,
   Occupation TEXT NOT NULL,
    AccountType TEXT NOT NULL,
    IsWisabi INT NOT NULL
 );   
-- CLEANING CUSTOMERS_LOOKUP TABLE
-- rename column with special character
alter table customers_lookup
rename column ï»¿CardholderID to CardholderID;

alter table customers_lookup
rename column `First Name` to FirstName;

alter table customers_lookup
rename column `Last Name` to LastName;

alter table customers_lookup
rename column `Birth Date` to BirthDate;

-- checking duplicate
select CardholderID, count(*)
from customers_lookup
group by CardholderID 
having count(*)>1;

-- check missing values
select CardholderID
from  customers_lookup
where CardholderID is null;

CREATE TABLE transaction_type(
    TransactionTypeID VARCHAR(50) PRIMARY KEY NOT NULL,
     TransactionTypeName TEXT NOT NULL
    );

CREATE TABLE transactions(
    TransactionID VARCHAR(50) PRIMARY KEY NOT NULL,
    TransactionStartDateTime TEXT NOT NULL,
	TransactionEndDateTime TEXT NOT NULL,
    CardholderID VARCHAR(50) NOT NULL,
    LocationID VARCHAR(255) NOT NULL,
    TransactionTypeID VARCHAR(50) NOT NULL,
    TransactionAmount INT NOT NULL
    );
    
-- CLEANING TRANSACTION TABLE
-- rename column with special character
alter table transactions
rename column ï»¿TransactionID to TransactionID;
-- check duplicate
select TransactionID, count(*)
from transactions
group by TransactionID 
having count(*)>1;
-- check missing values
select TransactionID
from  transactions
where TransactionID is null;

-- update transaction_type and transaction table by adding letters to transactiontypeid  to turn their data type to varchar

ALTER TABLE transaction_type
 modify COLUMN TransactionTypeID VARCHAR (50) PRIMARY KEY;
SET SQL_SAFE_UPDATES = 0;
update transaction_type
set TransactionTypeID = concat( "type", TransactionTypeID);
select * from transactions;

update transactions
set TransactionTypeID = concat( "type", TransactionTypeID);



-- update hour_lookup and calendar_lookup table by adding letters to hour_key  to turn their data type to varchar
ALTER TABLE hourlookup
 modify COLUMN Hour_Key VARCHAR(50) PRIMARY KEY;
SELECT * FROM hourlookup;

update hourlookup
set Hour_Key = concat(Hour_Key, " " "hour");
select * from calendar_lookup;




-- ALTERING TO ADD PRIMARY AND FOREIGN KEYS TO ALL TABLES
ALTER TABLE atm_location
 modify COLUMN LocationID VARCHAR(50) primary key;
 
ALTER TABLE calendar_lookup 
modify COLUMN Date VARCHAR(50) primary key;

ALTER TABLE customers_lookup
modify COLUMN CardholderID VARCHAR(50) primary key;
select * from customers_lookup;

ALTER TABLE transactions
 modify COLUMN TransactionID VARCHAR(50) primary key;
 
 ALTER TABLE transactions
 modify COLUMN LocationID VARCHAR(50);
 
 ALTER TABLE transactions
 modify COLUMN CardholderID VARCHAR(50);
 
 ALTER TABLE transactions
 modify COLUMN TransactionTypeID VARCHAR(50);
 
 -- LINK TABLES BY ADDING FOREIGN KEYS

ALTER TABLE transactions ADD CONSTRAINT   FOREIGN KEY (CardholderID) REFERENCES customers_lookup(CardholderID);
ALTER TABLE transactions ADD CONSTRAINT   FOREIGN KEY (LocationID) REFERENCES atm_location(LocationID);
ALTER TABLE transactions ADD CONSTRAINT   FOREIGN KEY (TransactionTypeID) REFERENCES transaction_type(TransactionTypeID);


-- QUERIES

-- 	1. Customer Behavior Analysis
-- identify the top 10 customers by total transaction volume and the top 10 by transaction frequency.
-- Analyze patterns in withdrawal and deposit transactions among these high-usage customers.


select * from transactions;
select * from customers_lookup;
-- top 10 customers by total transaction volume
SELECT CardholderID, SUM(TransactionAmount) AS TotalVolume
FROM Transactions
GROUP BY CardholderID
ORDER BY TotalVolume DESC
LIMIT 10;
-- top 10 by transaction frequency.
SELECT CardholderID, COUNT(TransactionID) AS Transaction_Frequency
FROM Transactions
GROUP BY CardholderID
ORDER BY Transaction_Frequency DESC
LIMIT 10;

-- top ten customer
SELECT tr.CardholderID, cl.FirstName,cl.LastName,  SUM(TransactionAmount) AS TotalVolume, COUNT(TransactionID) AS Transaction_Frequency
FROM Transactions as tr
join customers_lookup as cl on tr.CardholderID = cl.CardholderID
GROUP BY CardholderID
ORDER BY TotalVolume DESC, Transaction_Frequency DESC
LIMIT 10;




-- -- Analyze patterns in withdrawal and deposit transactions among these high-usage customers.
-- USING top 10 by transaction frequency AS SUBQUERY
SELECT CardholderID,
       SUM(CASE WHEN TransactionTypeName = 'Deposit' THEN TransactionAmount ELSE 0 END) AS TotalDeposits,
       SUM(CASE WHEN TransactionTypeName = 'Withdrawal' THEN TransactionAmount ELSE 0 END) AS TotalWithdrawals
FROM Transactions as tr
inner join transaction_type as tt on tr.TransactionTypeID = tt.TransactionTypeID
WHERE CardholderID IN (
    
    SELECT CardholderID
    FROM (
        SELECT CardholderID, COUNT(TransactionID) AS Transaction_Frequency
FROM Transactions
GROUP BY CardholderID
ORDER BY Transaction_Frequency DESC
LIMIT 10
    ) AS Withdrawal_or_Deposit
) 
GROUP BY CardholderID;


-- 2
-- Transaction Volume by Location
-- Calculate the total number of transactions and the average transaction amount for each ATM location.
-- Identify the locations with the highest and lowest transaction volumes.
-- Determine the percentage of withdrawals vs. deposits at each location.

-- the total number of transactions and the average transaction amount for each ATM location.
select * from atm_location;
select LocationID, count(TransactionID) as total_transaction, avg(TransactionAmount) as AVG_Transaction_Amount
from  transactions
group by LocationID;

--   the top ten location with the highest transaction volume

select LocationID, sum(TransactionAmount) as highest_Volume
from  transactions
group by LocationID
order by highest_Volume desc
limit 10;
--  the top ten location with the  lowest transaction volumes.
select LocationID, sum(TransactionAmount) as lowest_Volume
from  transactions
group by LocationID
order by lowest_Volume asc
limit 10;

-- Determine the percentage of withdrawals vs. deposits at each location.

SELECT LocationID,
SUM(CASE WHEN TransactionTypeID = 'type1' THEN 1 ELSE 0 END) AS WithdrawalCount, 
SUM(CASE WHEN TransactionTypeID = 'type2' THEN 1 ELSE 0 END) AS DepositCount 
FROM Transactions 
GROUP BY LocationID;

SELECT LocationID, WithdrawalCount, DepositCount, 
round(WithdrawalCount * 100.0 / (WithdrawalCount + DepositCount)) AS WithdrawalPercentage, 
round(DepositCount * 100.0 / (WithdrawalCount + DepositCount)) AS DepositPercentage 
FROM ( SELECT LocationID,
SUM(CASE WHEN TransactionTypeID = 'type1' THEN 1 ELSE 0 END) AS WithdrawalCount, 
SUM(CASE WHEN TransactionTypeID = 'type2' THEN 1 ELSE 0 END) AS DepositCount 
FROM Transactions 
GROUP BY LocationID ) AS TransactionCounts;

-- 3. Peak Usage Times
-- Using transaction timestamps, identify peak usage hours, days, and months across all locations.
-- Compare ATM usage patterns on weekends versus weekdays.

-- Using transaction timestamps, identify peak usage hours, days, and months across all locations.
SELECT   HOUR(STR_TO_DATE(TransactionStartDateTime, '%m/%d/%Y %H:%i')) AS Hour,
COUNT(TransactionID) AS TransactionCount
FROM Transactions
GROUP BY HOUR
ORDER BY TransactionCount DESC;

SELECT DAYOFWEEK(STR_TO_DATE(TransactionStartDateTime, '%m/%d/%Y %H:%i')) AS DAYOFWEEK,
COUNT(TransactionID) AS TransactionCount
FROM Transactions
GROUP BY DAYOFWEEK
ORDER BY TransactionCount DESC;


SELECT MONTH(STR_TO_DATE(TransactionStartDateTime, '%m/%d/%Y %H:%i')) AS MONTH,
COUNT(TransactionID) AS TransactionCount
FROM Transactions
GROUP BY MONTH
ORDER BY TransactionCount DESC;

-- Compare ATM usage patterns on weekends versus weekdays.
SELECT 
    CASE 
        WHEN DAYOFWEEK(STR_TO_DATE(TransactionStartDateTime, '%m/%d/%Y %H:%i')) IN (5, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    COUNT(TransactionID) AS TotalTransactions
FROM Transactions
GROUP BY DayType;


-- 4. Cash Flow Analysis
-- Calculate the average balance remaining after transactions for each customer.
-- Identify trends in average withdrawal amounts across different ATM locations.
-- Determine if there are any locations where ATMs frequently run low on cash by examining high transaction volumes or large average withdrawal amounts.

WITH RunningBalances AS (
    SELECT 
       CardholderID,
        TransactionStartDateTime,
        SUM(TransactionAmount) OVER (PARTITION BY CardholderID ORDER BY TransactionStartDateTime) AS RunningBalance
    FROM Transactions
)
SELECT CardholderID, AVG(RunningBalance) AS AverageBalance
FROM RunningBalances
GROUP BY CardholderID;

-- Identify trends in average withdrawal amounts across different ATM locations.
SELECT LocationID,
       AVG(TransactionAmount) AS AverageWithdrawalAmount
FROM Transactions
WHERE TransactionTypeID = "type1"
GROUP BY LocationID
order by LocationID asc;

-- Determine if there are any locations where ATMs frequently run low on cash by examining high transaction volumes or large average withdrawal amounts.

SELECT
LocationID,  COUNT(TransactionID) As total_transactions, AVG (TransactionAmount) AS avg_withdrawal_amount
FROM transactions
WHERE TransactionTypeID = "type1"
GROUP BY LocationID
order by total_transactions desc, avg_withdrawal_amount desc;

------
-- total amount withdrawn, deposited and transfered over the year
SELECT TransactionTypeID as withdrawal , SUM(TransactionAmount) as total_amount_withdrawn
FROM transactions
WHERE TransactionTypeID = 'type1'
group by TransactionTypeID; 

SELECT TransactionTypeID as deposit, SUM(TransactionAmount) as total_amount_deposited
FROM transactions
WHERE TransactionTypeID = 'type2'
group by TransactionTypeID;

SELECT TransactionTypeID as transfer, SUM(TransactionAmount) as total_amount_transferred
FROM transactions
WHERE TransactionTypeID = 'type4'
group by TransactionTypeID;






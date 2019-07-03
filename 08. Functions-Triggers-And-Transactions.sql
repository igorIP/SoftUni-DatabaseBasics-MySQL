#Exercises: Functions, Triggers and Transactions____________________

#Part I – Queries for SoftUni Database___________

#3. Town Names Starting With
use soft_uni;

delimiter //
create procedure  usp_get_towns_starting_with(str_start varchar(10))
begin
	select `name` as `town_name` 
    from `towns`
    where `name` like concat(str_start,'%')
    order by `town_name`;
end 
//
delimiter ;

call usp_get_towns_starting_with('S');
drop procedure usp_get_towns_starting_with;


#exercise from mysqltutorial.org
use classicmodels;

delimiter //
create procedure  get_order_by_cust(
in cust_no int,
OUT shipped INT,
OUT canceled INT,
OUT resolved INT,
OUT disputed INT
)
begin
	-- shipped
	select count(*) into shipped
    from orders
    where customerNumber = cust_no
    and status = 'Shipped';
    
    -- caneled
    select count(*) into canceled
    from orders
    where customerNumber = cust_no
    and status = 'Canceled';
    
     -- resolved
	SELECT
            count(*) INTO resolved
        FROM
            orders
        WHERE
            customerNumber = cust_no
                AND status = 'Resolved';
 
 -- disputed
 SELECT
            count(*) INTO disputed
        FROM
            orders
        WHERE
            customerNumber = cust_no
                AND status = 'Disputed';
end 
//
delimiter ;
	
CALL get_order_by_cust(141,@shipped,@canceled,@resolved,@disputed);
SELECT @shipped,@canceled,@resolved,@disputed;

#MySQL IF Statement-#exercise from mysqltutorial.org
use classicmodels;

delimiter //
create procedure  usp_getCustomerLevel(
in  p_customerNumber int(11),
out p_customerLevel  varchar(10)
)
begin
	declare creditlim double;
    
    select creditlimit into creditlim
    from customers
    where customerNumber = p_customerNumber;
    
    if credilim > 50000 then 
		set p_customerLevel = 'PLATINUM';
    elseif (credilim <= 50000 and credilim >= 10000) then
		set p_customerLevel = 'GOLD';
	elseif credilim < 10000  then
		set p_customerLevel = 'SILVER';
	end if;
end
//
delimiter ;

call usp_getCustomerLevel(15, customer_level);
drop procedure usp_getCustomerLevel;

#MySQL CASE Statement
DELIMITER $$
 
CREATE PROCEDURE GetCustomerLevel(
 in  p_customerNumber int(11), 
 out p_customerLevel  varchar(10))
BEGIN
    DECLARE creditlim double;
 
    SELECT creditlimit INTO creditlim
 FROM customers
 WHERE customerNumber = p_customerNumber;
 
    CASE  
 WHEN creditlim > 50000 THEN 
    SET p_customerLevel = 'PLATINUM';
 WHEN (creditlim <= 50000 AND creditlim >= 10000) THEN
    SET p_customerLevel = 'GOLD';
 WHEN creditlim < 10000 THEN
    SET p_customerLevel = 'SILVER';
 END CASE;
 
END$$

-- test
CALL GetCustomerLevel(112,@level);
SELECT @level AS 'Customer Level';

#10. Future Value Function
SET GLOBAL log_bin_trust_function_creators = 1;

delimiter //
create function ufn_calculate_future_value(
i DECIMAL(10,2), 
r DECIMAL(10,2),
y int)
returns DECIMAL(10,4)
begin
    return  i * ( power((1 + r), y));
end
//
delimiter ;

select ufn_calculate_future_value(1000, 0.1, 5);
drop function if exists  ufn_calculate_future_value;

#11. Calculating Interest

delimiter $$
create procedure usp_calculate_future_value_for_account(
account_id int,
interest_rate DECIMAL)
begin
	select 
		ah.id,
        ah.first_name,
        ah.last_name,
        a.balance as current_balance,
		ufn_calculate_future_value(a.balance,interest_rate, 5) as balance_in_5_years
	from
	account_holders AS ah
            JOIN
        accounts AS a ON ah.id=a.account_holder_id
    WHERE a.id = account_id;
end$$

call usp_calculate_future_value_for_account(2,0.1);
drop procedure usp_calculate_future_value_for_account;


#12. Deposit Money

DELIMITER $$
CREATE PROCEDURE usp_deposit_money(
    account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0 THEN
        START TRANSACTION;
        
        UPDATE `accounts` AS a 
        SET 
            a.balance = a.balance + money_amount
        WHERE
            a.id = account_id;
        
        IF (SELECT a.balance 
            FROM `accounts` AS a 
            WHERE a.id = account_id) < 0
            THEN ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END $$
DELIMITER ;

CALL usp_deposit_money(1, 10);

#13.Withdraw Money
DELIMITER $$
CREATE PROCEDURE  usp_withdraw_money(
    account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0 THEN
        START TRANSACTION;
        
        UPDATE `accounts` AS a 
        SET 
            a.balance = a.balance +-money_amount
        WHERE
            a.id = account_id;
        
        IF (SELECT a.balance 
            FROM `accounts` AS a 
            WHERE a.id = account_id) < 0
            THEN ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END $$
DELIMITER ;

CALL  usp_withdraw_money(1, 10);

#14.Money Transfer
DELIMITER //
CREATE PROCEDURE  usp_transfer_money(
	from_account_id DECIMAL(19, 4), to_account_id DECIMAL(19, 4), amount_to_transfer DECIMAL(19, 4))
BEGIN
	IF amount_to_transfer > 0 
		AND 
			from_account_id <> to_account_id
		AND (
			SELECT a.id 
            FROM `accounts` AS a 
            WHERE a.id = to_account_id) IS NOT NULL
        AND (
			SELECT a.id 
            FROM `accounts` AS a 
            WHERE a.id = from_account_id) IS NOT NULL
        AND(
			SELECT a.balance 
            FROM  `accounts` as `a`
            where a.id = from_account_id
        ) >= amount_to_transfer
	THEN 
		start transaction;
        
		update accounts as a
        set a.balance = a.balance + amount_to_transfer
        where a.id = to_account_id;
        
        update accounts as a
        set a.balance = a.balance - amount_to_transfer
        where a.id = from_account_id;
        
		if(
        SELECT a.balance
        from accounts as a
        where a.id = from_account_id < 0 
        ) then rollback;
        
        else commit;
		end if;    
    end if;    
END
//
DELIMITER ;


CALL usp_transfer_money(1, 2, 10);
CALL usp_transfer_money(2, 1, 10);
drop procedure if exists usp_transfer_money;

#15. Log Accounts Trigger
create table logs(
log_id int unsigned not null primary key auto_increment, 
account_id int not null, 
old_sum decimal(19, 4) not null,
new_sum decimal(19, 4) not null
);

DELIMITER $$
create trigger balance_change
	after update on accounts
	for each row 
begin
	if old.balance <> new.balance then
		insert into logs(
			`account_id`, `old_sum`, `new_sum`)
            values(
             OLD.account_holder_id, OLD.balance, NEW.balance);
	end if;
end$$
DELIMITER ;
		
CALL usp_transfer_money(4, 3, 10);
CALL usp_transfer_money(3, 4, 10);		

DROP TRIGGER IF EXISTS `soft_uni`.balance_change;
DROP TABLE IF EXISTS `logs`;

#16. Emails Trigger
CREATE TABLE `notification_emails` (
    `id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    `recipient` INT(11) NOT NULL,
    `subject` VARCHAR(50) NOT NULL,
    `body` VARCHAR(255) NOT NULL
);

DELIMITER $$
CREATE TRIGGER `tr_notification_emails`
AFTER INSERT ON `logs`
FOR EACH ROW
BEGIN
    INSERT INTO `notification_emails` 
        (`recipient`, `subject`, `body`)
    VALUES (
        NEW.account_id, 
        CONCAT('Balance change for account: ', NEW.account_id), 
        CONCAT('On ', DATE_FORMAT(NOW(), '%b %d %Y at %r'), ' your balance was changed from ', ROUND(NEW.old_sum, 2), ' to ', ROUND(NEW.new_sum, 2), '.'));
END $$
DELIMITER ;

SELECT * FROM `notification_emails`;

DROP TRIGGER IF EXISTS `bank`.tr_notification_emails;
DROP TABLE IF EXISTS `notification_emails`;


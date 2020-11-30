DROP TABLE DRIVERS cascade constraints;
DROP TABLE CARS cascade constraints;
DROP TABLE OPERATORS cascade constraints;
DROP TABLE BOOKINGS cascade constraints;
DROP TABLE CLIENTS cascade constraints;
DROP TABLE PAYMENTS cascade constraints;
DROP TABLE REVENUE cascade constraints;
DROP TABLE O_SHIFTS cascade constraints;
DROP TABLE D_SHIFTS cascade constraints;
DROP SEQUENCE payment_sequence;
DROP SEQUENCE revenue_sequence;

CREATE SEQUENCE payment_sequence
MINVALUE 1
START WITH 1
INCREMENT BY 1
CACHE 10;

CREATE SEQUENCE revenue_sequence
MINVALUE 1
START WITH 1
INCREMENT BY 1
CACHE 10;

CREATE TABLE DRIVERS (
    d_id NUMBER(5) PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(60) NOT NULL,
    gender CHAR(1),
    phone_number NUMBER(11) UNIQUE,
    date_of_birth DATE,
    date_employed DATE,
    national_insurance VARCHAR(9) UNIQUE
);

CREATE TABLE CARS (
    registration VARCHAR(12) PRIMARY KEY,
    car_make VARCHAR(20),
    car_model VARCHAR(20),
    last_MOT DATE,
    status VARCHAR(20),
    d_id NUMBER(5),
    FOREIGN KEY (d_id) REFERENCES DRIVERS(d_id) ON DELETE SET NULL
);

CREATE TABLE OPERATORS(
    op_id NUMBER(5) PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(60) NOT NULL,
    gender CHAR(1),
    phone_number NUMBER(11) UNIQUE,
    date_of_birth DATE,
    date_employed DATE
);

CREATE TABLE CLIENTS(
    client_id NUMBER(6) PRIMARY KEY,
    client_type VARCHAR(10) NOT NULL,
    first_name VARCHAR (30),
    last_name VARCHAR(30),
    address VARCHAR(60),
    card_number NUMBER(16),
    CVV NUMBER(3),
    expiry VARCHAR(5),
    phone_number NUMBER(11) UNIQUE
);

CREATE TABLE BOOKINGS(
    booking_id INT PRIMARY KEY,
    op_id NUMBER(5),
    d_id NUMBER(5),
    client_id NUMBER(6), 
    type_booking VARCHAR(10),
    time_of_booking DATE, 
    time_of_pickup DATE,
    pickup_location VARCHAR(30),
    destination VARCHAR(30),
    payment_type VARCHAR(5), 
    price INT,
    FOREIGN KEY(d_id) REFERENCES DRIVERS(d_id) ON DELETE SET NULL,
    FOREIGN KEY(op_id) REFERENCES OPERATORS(op_id) ON DELETE SET NULL,
    FOREIGN KEY(client_id) REFERENCES CLIENTS(client_id) ON DELETE SET NULL
);


CREATE TABLE PAYMENTS (
    payment_id INT PRIMARY KEY,
    booking_id INT,
    card_number NUMBER(16),
    CVV NUMBER(3),
    expiry VARCHAR(5),
    price INT,
    FOREIGN KEY (booking_id) REFERENCES BOOKINGS(booking_id) ON DELETE SET NULL
);

CREATE TABLE REVENUE (
    rev_id INT PRIMARY KEY,
    booking_id,
    d_id NUMBER(5),
    REVENUE INT,
    FOREIGN KEY (d_id) REFERENCES DRIVERS(d_id) ON DELETE SET NULL,
    FOREIGN KEY (booking_id) REFERENCES BOOKINGS(booking_id) ON DELETE SET NULL
);

CREATE TABLE O_SHIFTS(
    shift_id INT PRIMARY KEY, 
    op_id number(5),
    shift_start_hour INT,
    shift_start_min INT,
    shift_hours INT,
    FOREIGN KEY (op_id) REFERENCES OPERATORS(op_id) ON DELETE SET NULL 
);

CREATE TABLE D_SHIFTS(
    shift_id INT PRIMARY KEY, 
    d_id number(5),
    shift_start_hour INT,
    shift_start_min INT,
    shift_hours INT,
    FOREIGN KEY (d_id) REFERENCES DRIVERS(d_id) ON DELETE SET NULL 
);

CREATE TRIGGER national_insurance_check
    BEFORE INSERT ON DRIVERS
    FOR EACH ROW
    BEGIN
    IF NOT REGEXP_LIKE  (:NEW.national_insurance,'^[A-CEGHJ-PR-TW-Z]{1}[A-CEGHJ-NPR-TW-Z]{1}[0-9]{6}[A-DFM]{0,1}$') THEN 
         RAISE_APPLICATION_ERROR(-20501,'National Insurance Invalid');
    END IF;

END;
/

CREATE OR REPLACE TRIGGER do_auto_increment_payment
    BEFORE INSERT ON PAYMENTS
    FOR EACH ROW
    BEGIN
        :NEW.payment_id :=payment_sequence.nextval;
END;
/

CREATE OR REPLACE TRIGGER payment_insert_trg
 AFTER INSERT ON bookings
 FOR EACH ROW
    WHEN((NEW.payment_type='CASH') OR (NEW.payment_type='CARD'))
 DECLARE
 c_number NUMBER(16);
 CVV1 NUMBER(3);
 expiry1 VARCHAR(5);
    BEGIN
        SELECT card_number INTO c_number FROM CLIENTS WHERE client_id = :NEW.client_id;
        SELECT CVV INTO CVV1 FROM CLIENTS WHERE client_id = :NEW.client_id;
        SELECT expiry INTO expiry1 FROM CLIENTS WHERE client_id = :NEW.client_id;
        IF :NEW.payment_type= 'CASH' THEN
        INSERT INTO PAYMENTS
        VALUES (1, :NEW.booking_id, NULL, NULL,NULL,:NEW.price);
        END IF;
        IF :NEW.payment_type= 'CARD' THEN
        INSERT INTO PAYMENTS
        VALUES (1, :NEW.booking_id, c_number, CVV1,expiry1,:NEW.price);
        END IF;

END;
/

CREATE OR REPLACE TRIGGER revenue_insert_trg
 AFTER INSERT ON bookings
 FOR EACH ROW
    BEGIN
        INSERT INTO REVENUE
        VALUES (revenue_sequence.nextval,:NEW.booking_id ,:NEW.d_id, :NEW.price*0.3);
        INSERT INTO REVENUE
        VALUES (revenue_sequence.nextval,:NEW.booking_id, NULL, :NEW.price*0.7);
END;
/

CREATE TRIGGER client_check_trg -- enum check
    BEFORE INSERT ON CLIENTS
    FOR EACH ROW
        BEGIN
        IF :NEW.client_type !='Corporate' AND :NEW.client_type !='Private'  THEN
            RAISE_APPLICATION_ERROR(-20500, 'A client can only be Private or Corporate');
        END IF;
END;
/

CREATE TRIGGER payment_notification
    AFTER INSERT ON bookings
    FOR EACH ROW
    BEGIN
    IF :NEW.payment_type = 'CASH' THEN
        DBMS_OUTPUT.PUT_LINE('Successful Payment By Cash');
    END IF;
    IF :NEW.payment_type = 'CARD' THEN
        DBMS_OUTPUT.PUT_LINE('Successful Payment By Card');
    END IF;
END;
/

INSERT INTO DRIVERS VALUES(10000,'James','Smith','Linard Street AV 32', 'M', 07654765436, '01-JAN-98','11-JAN-18','PT034537A');
INSERT INTO DRIVERS VALUES(13300,'Stacey','Conor','Brum Street AV 12', 'F', 07683065436, '21-FEB-82','07-JUN-08','EH278153B');
INSERT INTO DRIVERS VALUES(12100,'Millard','Tempe','Ford Street AV 251', 'M', 07654524436, '20-MAR-79','11-AUG-98','OM044192C');
INSERT INTO DRIVERS VALUES(12120,'Mo','Crope','London Road ST 34', 'F', 07654760086, '11-JAN-95','08-NOV-19','TG702217B');
INSERT INTO DRIVERS VALUES(10100,'Appe','Niko','New cross AV 27', 'M', 07612365436, '03-APR-93','17-JAN-13','CS914945B');
INSERT INTO DRIVERS VALUES(10011,'Ronaldo','Vetty','Brum Road 233', 'M', 07654069436, '18-MAY-90','11-JAN-11','OE794542A');
INSERT INTO DRIVERS VALUES(13001,'Rhi','Biden','Manny Atown road', 'F', 07654711436, '04-JUL-92','01-DEC-14','NA112240C');

INSERT INTO CARS VALUES('DC4RTQ','HONDA','CIVIC','04 DEC 2019', 'Road Worthy', 13300);
INSERT INTO CARS VALUES('MA3RDT','MERCEDES','VITO','12 JAN 2020', 'Road Worthy', 12120);
INSERT INTO CARS VALUES('J9GF6D','TOYOTA','PRUIS','24 NOV 2019', 'Road Worthy', 12100);
INSERT INTO CARS VALUES('PHFJD7','FORD','FIESTA','04 DEC 2019', 'Road Worthy', 10000);
INSERT INTO CARS VALUES('H67DGF','HONDA','CIVIC','21 DEC 2019', 'Road Worthy', 13300);
INSERT INTO CARS VALUES('KD64HX','HONDA','CIVIC','12 AUG 2018', 'Road Worthy', 10100);
INSERT INTO CARS VALUES('Y40SK5','HONDA','CIVIC','04 DEC 2019', 'Written Off', NULL);
INSERT INTO CARS VALUES('HS63FD','TOYOTA','PRUIS','24 APR 2018', 'In for service', 10011);
INSERT INTO CARS VALUES('OSJ63F','FORD','FOCUS','24 NOV 2017', 'Road Worthy', 12100);
INSERT INTO CARS VALUES('SJR74H','TOYOTA','PRUIS','24 NOV 2017', 'Road Worthy', 12100);
INSERT INTO CARS VALUES('34JURI','TOYOTA','PRUIS','24 AUG 2020', 'Road Worthy', 13001);

INSERT INTO OPERATORS VALUES(20020,'Lisa','Rock','Maydord Street 15', 'F', 07654233136, '11-FEB-96','14-OCT-15');
INSERT INTO OPERATORS VALUES(20120,'Vlad','Marop','Christ Street 22', 'M', 07652233136, '03-APR-91','11-APR-17');
INSERT INTO OPERATORS VALUES(22420,'Kishan','Jason','Ravens Street 56', 'M', 07004200136, '29-JAN-95','04-SEP-15');
INSERT INTO OPERATORS VALUES(21421,'Tyrone','William','Merdock Street 52', 'M', 07611233336, '17-SEP-90','04-SEP-15');
INSERT INTO OPERATORS VALUES(27020,'Mason','Charles','Vivian Road 33', 'M', 07651233900, '19-JAN-89','11-MAR-07');
INSERT INTO OPERATORS VALUES(27420,'Holly','Kennedy','Kappe Street 02', 'F', 07954213206, '22-OCT-86','11-FEB-07');
INSERT INTO OPERATORS VALUES(27120,'Jay','Raymond','Kalyso Road 13', 'M', 07651231670, '19-JUN-90','11-APR-07');
INSERT INTO OPERATORS VALUES(27360,'Martin','Tyler','Valocan Street 52', 'M', 07953413206, '22-OCT-88','01-AUG-07');

INSERT INTO CLIENTS VALUES(30010,'Corporate','Eric','Turk','Sedge Street 32',7854126589652314, 587, '02-23',07953213996);
INSERT INTO CLIENTS VALUES(32010,'Private','Stacey','Red','Flower Street 122',5687456896214568,245, '09-21',079533453996);
INSERT INTO CLIENTS VALUES(30410,'Corporate','Linda','Foster','Washington Street 12',9852645783214567,221,'07-24',07951211291);
INSERT INTO CLIENTS VALUES(32110,'Private','Chris','Tucker','Florida Street 02',2476148236547892,711, '11-22',07943214396);
INSERT INTO CLIENTS VALUES(30450,'Private','Mark','Cuban','Green Bay ST 41', 4587982156942382,247,'12-21',07973652185);
INSERT INTO CLIENTS VALUES(30111,'Private','Jack','Ryan','Grender Town  21', 4587982177742382,247,'12-20',07973111185);

INSERT INTO BOOKINGS VALUES(0001,20020,12100,30410,'One Time',TO_DATE('30/11/20 18:00', 'DD/MM/YY hh24:mi'),TO_DATE('02/12/20 09:00', 'DD/MM/YY hh24:mi'),'London Street','Heathrow' ,'CASH',90);
INSERT INTO BOOKINGS VALUES(0002,27020,13001,30450,'Daily',TO_DATE('25/11/20 15:00', 'DD/MM/YY hh24:mi'),TO_DATE('27/11/20 08:15', 'DD/MM/YY hh24:mi'),'Dublin Street','Luton Station' ,'CARD',150);
INSERT INTO BOOKINGS VALUES(0003,27360,10000,32010,'Weekly',TO_DATE('02/10/20 14:00', 'DD/MM/YY hh24:mi'),TO_DATE('19/11/20 12:00', 'DD/MM/YY hh24:mi'),'Oxford Circus','Cambridge Centre' ,'CARD',100);
INSERT INTO BOOKINGS VALUES(0004,27120,10100,32110,'One Time',TO_DATE('11/11/20 17:00', 'DD/MM/YY hh24:mi'),TO_DATE('12/11/20 18:00', 'DD/MM/YY hh24:mi'),'Kensington Avenue','Brighton City' ,'CARD',210);
INSERT INTO BOOKINGS VALUES(0005,20120,13300,30010,'Monthly',TO_DATE('07/12/20 08:00', 'DD/MM/YY hh24:mi'),TO_DATE('13/12/20 17:00', 'DD/MM/YY hh24:mi'),'Bromley High Street','Gatwick Aiport' ,'CASH',95);
INSERT INTO BOOKINGS VALUES(0006,20120,10100,32110,'One Time',TO_DATE('14/10/20 18:00', 'DD/MM/YY hh24:mi'),TO_DATE('16/10/20 18:00', 'DD/MM/YY hh24:mi'),'Kensington Avenue','Michigan City' ,'CARD',250);
INSERT INTO BOOKINGS VALUES(0007,21421,13001,32110,'One Time',TO_DATE('16/11/20 12:00', 'DD/MM/YY hh24:mi'),TO_DATE('24/11/20 18:00', 'DD/MM/YY hh24:mi'),'Kensington Avenue','Hull City' ,'CASH',110);

INSERT INTO O_SHIFTS VALUES(0001,22420,09,30,8);
INSERT INTO O_SHIFTS VALUES(0002,27360,09,30,8);
INSERT INTO O_SHIFTS VALUES(0003,27420,07,30,8);
INSERT INTO O_SHIFTS VALUES(0004,27120,08,30,8);
INSERT INTO O_SHIFTS VALUES(0005,22420,10,30,9);

INSERT INTO D_SHIFTS VALUES(0001,13300,11,30,7);
INSERT INTO D_SHIFTS VALUES(0002,10000,09,30,8);
INSERT INTO D_SHIFTS VALUES(0003,12120,07,30,8);
INSERT INTO D_SHIFTS VALUES(0004,10011,08,30,8);
INSERT INTO D_SHIFTS VALUES(0005,10000,06,15,10);

-- These queries will allow us to check if the triggers were successful
SELECT * FROM PAYMENTS;
select booking_id,op_id,d_id,client_id,type_booking,to_char(time_of_booking, 'DD/MM/YY  HH:MIAM') as time_of_booking,to_char(time_of_pickup, 'DD/MM/YY  HH:MIAM') as time_of_pickup,pickup_location,destination,payment_type FROM bookings;
select * from clients;
select * from revenue;
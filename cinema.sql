--Удаляем все, если вдруг у вас это было--

DROP TABLE IF EXISTS CINEMA CASCADE;
DROP TABLE IF EXISTS HALL CASCADE;
DROP TABLE IF EXISTS FILM CASCADE;
DROP TABLE IF EXISTS SESSION CASCADE;
DROP TABLE IF EXISTS CUSTOMER CASCADE;
DROP TABLE IF EXISTS TICKET CASCADE;
DROP TABLE IF EXISTS REVIEW CASCADE;

DROP TABLE IF EXISTS TOTAL_INFO_TICKET_LOG CASCADE;
DROP FUNCTION IF EXISTS c_list() CASCADE;

DROP FUNCTION IF EXISTS log_ticket() CASCADE;
DROP FUNCTION IF EXISTS summary_ticket_insert() CASCADE;
DROP FUNCTION IF EXISTS summary_ticket_delete() CASCADE;
DROP TABLE IF EXISTS CINEMA_LIST CASCADE;
DROP FUNCTION IF EXISTS TAKE_CINEMA(ID_TICKET INTEGER) CASCADE;

--Создаем таблцу Синема--

CREATE TABLE CINEMA(
  ID_CINEMA INTEGER PRIMARY KEY,
  NAME VARCHAR(40) NOT NULL,
  PLACE VARCHAR(30)
);

--ТРИГГЕР, ДЕЛАЕМ ТАБЛИЦУ, КОТОРАЯ СОХРАНЯЕТ ПРИБЫЛЬ КИНОТЕАТРА И КОЛВО ПРОДАННЫХ БИЛЕТОВ---

--сама таблица--
CREATE TABLE CINEMA_LIST(ID_CINEMA INTEGER, SUMMARY_COST INTEGER, TICKET_COUNT INTEGER);

CREATE FUNCTION c_list() RETURNS trigger AS $c_list$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
             INSERT INTO CINEMA_LIST VALUES(NEW.ID_CINEMA, 0, 0);
        END IF;
        RETURN NULL;
    END;
$c_list$ LANGUAGE plpgsql;

CREATE TRIGGER c_list AFTER INSERT OR UPDATE OR DELETE ON CINEMA
  FOR EACH ROW EXECUTE PROCEDURE c_list();

--КОНЕЦ ТРИГГЕРА--

--Процедура для заполнения таблицы кинотеатр и тест для нее--

--CREATE OR REPLACE PROCEDURE create_cinema_list(a INTEGER, _name VARCHAR(40), _place VARCHAR(30))
--LANGUAGE plpgsql
--AS $$
--    insert into CINEMA values($1, $2, $3);
--$$;

--CALL create_cinema_list(6, 'Золотой Октябрь', NULL);

--заполняем таблицу данными--

insert into CINEMA values(1,'Красный октябрь', 'Москва');
insert into CINEMA values(2,'Пионер', 'Самара');
insert into CINEMA values(3,'Минск', 'Минск');
insert into CINEMA values(4,'60-летия Октябрьской революции', 'Москва');
insert into CINEMA values(5,'Первомайский', NULL);

--таблица всех заллов--

CREATE TABLE HALL(
  ID_HALL INTEGER PRIMARY KEY,
  ID_CINEMA INTEGER REFERENCES CINEMA(ID_CINEMA) NOT NULL,
  HALL_NUM INTEGER NOT NULL CHECK (HALL_NUM >= 0 AND HALL_NUM <= 100),
  COUNT_PLACES INTEGER,
  SPECIFICATION VARCHAR(4) CHECK (SPECIFICATION = 'base' OR SPECIFICATION = 'vip')
);

insert into HALL values(1, 1, 1, 20, 'base');
insert into HALL values(2, 1, 2, 30, 'base');
insert into HALL values(3, 1, 3, 20, 'vip');
insert into HALL values(4, 2, 1, NULL,'base');
insert into HALL values(5, 2, 2, 40, NULL);
insert into HALL values(6, 3, 1, 20, 'base');
insert into HALL values(7, 3, 2, 30, 'vip');
insert into HALL values(8, 4, 1, 25, 'base');

--таблица всех фильмов--

CREATE TABLE FILM(
  ID_FILM INTEGER PRIMARY KEY,
  FILM VARCHAR(30) NOT NULL,
  START DATE CHECK (START >= '01-JAN-1900'),
  DURATION INTEGER CHECK (DURATION > 0) NOT NULL,
  GENRE VARCHAR(15) CHECK (GENRE = 'horror'OR GENRE = 'documentary' OR GENRE = 'comedy' OR GENRE = 'drama' OR GENRE = 'animated' OR GENRE = 'sci-fi' OR GENRE = 'thriller'),
  MIN_AGE INTEGER
);

insert into FILM values(1, 'Пила', '21-JUN-2000', 120, 'horror', 18);
insert into FILM values(2, 'Бойцовский клуб', '15-MAR-1999', 130, 'drama', 18);
insert into FILM values(3, 'Великая жизнь Ленина', NULL, 300, 'documentary', 12);
insert into FILM values(4, 'Король Лев', '15-FEB-1994', 111, 'animated', 0);
insert into FILM values(5, 'Достучаться до небес', '13-JUL-1997', 115, 'drama', NULL);
insert into FILM values(6, 'Очень страшное кино 21', '19-APR-2019', 100, NULL, 18);

--таблицы всех сеансов--

CREATE TABLE SESSION(
  ID_SESSION INTEGER PRIMARY KEY,
  ID_HALL INTEGER REFERENCES HALL(ID_HALL) NOT NULL,
  ID_FILM INTEGER REFERENCES FILM(ID_FILM) NOT NULL,
  FILM_START TIMESTAMP NOT NULL
);

insert into SESSION values(1, 1, 1, '2019-05-13 10:25:00');
insert into SESSION values(2, 1, 2, '2019-05-19 00:35:00');
insert into SESSION values(3, 7, 3, '2019-05-11 12:00:00');
insert into SESSION values(4, 2, 4, '2019-05-9 17:15:00');
insert into SESSION values(5, 2, 5, '2019-05-7 19:45:00');
insert into SESSION values(6, 3, 6, '2019-05-14 13:40:00');
insert into SESSION values(7, 4, 3, '2019-05-31 14:50:00');
insert into SESSION values(8, 5, 4, '2019-05-19 15:10:00');
insert into SESSION values(9, 6, 6, '2019-05-19 16:35:00');
insert into SESSION values(10, 8, 1, '2019-05-18 20:10:00');
insert into SESSION values(11, 8, 2, '2019-05-17 21:00:00');

--таблица зрителей--

CREATE TABLE CUSTOMER(
  ID_CUSTOMER INTEGER PRIMARY KEY,
  AGE INTEGER,
  NAME VARCHAR(50) NOT NULL
);

insert into CUSTOMER values(1, 12, 'Иванов Иван');
insert into CUSTOMER values(2, 11, 'Николева Анна');
insert into CUSTOMER values(3, 17, 'Деркач Илья');
insert into CUSTOMER values(4, 55, 'Зайцев Сергей');
insert into CUSTOMER values(5, NULL, 'Корабельникова Мария');
insert into CUSTOMER values(6, 33, 'Волкова Арина');

--таблица билетов--

CREATE TABLE TICKET(
  ID_TICKET INTEGER PRIMARY KEY NOT NULL,
  ID_CUSTOMER INTEGER REFERENCES CUSTOMER(ID_CUSTOMER) NOT NULL,
  ID_SESSION INTEGER REFERENCES SESSION(ID_SESSION) NOT NULL,
  BUY_TIME DATE CHECK (BUY_TIME >= '01-JAN-1900' AND BUY_TIME <= now()::date),
  PRICE INTEGER NOT NULL,
  PLACE INTEGER NOT NULL
);

--ТРИГГЕР ЗАПОЛНЕНИЯ ТАБЛИЦЫ ПРО ДОХОД КИНОТЕАТРОВ--

--Процедура поиска кинотеатра по билету--

CREATE FUNCTION TAKE_CINEMA (ticket_id INTEGER) RETURNS INTEGER AS $$
    DECLARE
        result INTEGER;
    BEGIN

        SELECT MAX(CINEMA.ID_CINEMA) INTO result
        FROM CINEMA
        INNER JOIN HALL
        ON CINEMA.ID_CINEMA = HALL.ID_CINEMA
        INNER JOIN SESSION
        ON HALL.ID_HALL = SESSION.ID_HALL
        INNER JOIN TICKET
        ON SESSION.ID_SESSION = TICKET.ID_SESSION
        WHERE TICKET.ID_TICKET = $1;

        IF result IS NULL THEN
            RAISE EXCEPTION 'Ticket wasn''t found';
        END IF;

        RETURN result;
    END;
$$ LANGUAGE plpgsql;

--ТРИГГЕР ДЛЯ ИНСЕРТА + АПДЕТА(обновление таблицы)--

CREATE FUNCTION summary_ticket_insert() RETURNS trigger AS $summary_ticket_insert$
    DECLARE
        res INTEGER;
    BEGIN
        res = TAKE_CINEMA(NEW.ID_TICKET);
        --ПРОВЕРКА РАБОТОСПОСОБНОСТИ ИСКЛЮЧЕНИЯ НЕСУЩЕСТВУЮЩЕГО БИЛЕТА--res = TAKE_CINEMA(100);
        IF(TG_OP = 'UPDATE') THEN
            UPDATE CINEMA_LIST SET SUMMARY_COST = SUMMARY_COST + NEW.PRICE - OLD.PRICE, TICKET_COUNT = TICKET_COUNT WHERE ID_CINEMA = res;
            RETURN NEW;

        ELSEIF (TG_OP = 'INSERT') THEN
            UPDATE CINEMA_LIST SET SUMMARY_COST = SUMMARY_COST + NEW.PRICE, TICKET_COUNT = TICKET_COUNT + 1 WHERE ID_CINEMA = res;
            RETURN NEW;

        END IF;

        RETURN NULL;
    END;
$summary_ticket_insert$ LANGUAGE plpgsql;

CREATE TRIGGER summary_ticket_insert AFTER INSERT OR UPDATE ON TICKET
  FOR EACH ROW EXECUTE PROCEDURE summary_ticket_insert();

--ТРИГГЕР ДЛЯ ДЕЛИТА(обновление таблицы)--

CREATE FUNCTION summary_ticket_delete() RETURNS trigger AS $summary_ticket_delete$
    DECLARE
        res INTEGER;
    BEGIN
        res = TAKE_CINEMA(OLD.ID_TICKET);

        UPDATE CINEMA_LIST SET SUMMARY_COST = SUMMARY_COST - OLD.PRICE, TICKET_COUNT = TICKET_COUNT - 1 WHERE ID_CINEMA = res;
        RETURN OLD;
    END;
$summary_ticket_delete$ LANGUAGE plpgsql;

CREATE TRIGGER summary_ticket_delete BEFORE DELETE ON TICKET
  FOR EACH ROW EXECUTE PROCEDURE summary_ticket_delete();

--КОНЕЦ ТРИГГЕРА ОБНОВЛЕНИЯ ТАБЛИЦЫ--

--ТРИГГЕР ЛОГИРОВАНИЯ--

CREATE TABLE TOTAL_INFO_TICKET_LOG(
    TIME TIMESTAMP,
    OPERATION VARCHAR(8) CHECK (OPERATION = 'INSERT' OR OPERATION = 'DELETE' OR OPERATION = 'UPDATE')
);

CREATE FUNCTION log_ticket() RETURNS trigger AS $log_ticket$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO TOTAL_INFO_TICKET_LOG VALUES(current_timestamp, TG_OP);
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO TOTAL_INFO_TICKET_LOG VALUES(current_timestamp, TG_OP);
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO TOTAL_INFO_TICKET_LOG VALUES(current_timestamp, TG_OP);
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$log_ticket$ LANGUAGE plpgsql;

CREATE TRIGGER log_ticket BEFORE INSERT OR UPDATE OR DELETE ON TICKET
  FOR EACH ROW EXECUTE PROCEDURE log_ticket();

--КОНЕЦ ЛОГИРОВАНИЯ--


insert into TICKET values(1, 1, 1, '01-JAN-2019', 150, 5);
insert into TICKET values(2, 1, 2, '02-JAN-2019', 170, 10);
insert into TICKET values(3, 1, 3, '03-JAN-2019', 150, 15);
insert into TICKET values(4, 2, 4, '04-JAN-2019', 200, 1);
insert into TICKET values(5, 2, 5, '05-JAN-2019', 250, 2);
insert into TICKET values(6, 2, 6, '06-JAN-2019', 300, 3);
insert into TICKET values(7, 3, 7, '07-JAN-2019', 270, 4);
insert into TICKET values(8, 3, 8, '08-JAN-2019', 600, 7);
insert into TICKET values(9, 3, 1, '09-JAN-2019', 200, 11);
insert into TICKET values(10, 4,2 , '01-JAN-2019', 150, 12);
insert into TICKET values(11, 4, 4, '02-JAN-2019', 400, 19);
insert into TICKET values(12, 4, 9, '03-JAN-2019', 350, 18);
insert into TICKET values(13, 5, 11, '04-JAN-2019', 200, 17);
insert into TICKET values(14, 6, 11, '05-JAN-2019', 110, 16);

DELETE from TICKET where ID_TICKET = 14;
UPDATE TICKET SET PRICE = 1000 WHERE price = 270;

--вывод резльтата действий триггеров--

SELECT *
FROM TOTAL_INFO_TICKET_LOG;

SELECT *
FROM CINEMA_LIST
ORDER BY ID_CINEMA;

--таблица оценок--

CREATE TABLE REVIEW(
  ID_CUSTOMER INTEGER REFERENCES CUSTOMER(ID_CUSTOMER) NOT NULL,
  ID_FILM INTEGER REFERENCES FILM(ID_FILM) NOT NULL,
  MARK INTEGER CHECK (MARK >= 0 AND MARK <= 10) NOT NULL,
  REVIEW TEXT NOT NULL
);

insert into REVIEW values(1, 2, 8, 'Понравилось');
insert into REVIEW values(3, 1, 3, 'Не понравилось');
insert into REVIEW values(5, 3, 9, 'Хороший фильм');
insert into REVIEW values(4, 4, 3, 'Сходил с женой и разочаровался');
insert into REVIEW values(5, 5, 10, '10/10');
insert into REVIEW values(6, 5, 6, 'почему я должен писать текст в оценке фильма??');
insert into REVIEW values(2, 4, 4, 'так себе');
insert into REVIEW values(3, 3, 7, 'схожу с друзьями еще раз');

--ЗАПРОСЫ--

--Вывести имя всех людей, которые сходили на два и более cеанса--

SELECT NAME
FROM CUSTOMER
INNER JOIN TICKET
ON CUSTOMER.ID_CUSTOMER = TICKET.ID_CUSTOMER
GROUP BY NAME
HAVING COUNT(ID_TICKET) > 1;

--Вывести имя и возраст тех людей, которые сходили на фильм не по своему возрасту--

SELECT DISTINCT NAME, AGE
FROM CUSTOMER
INNER JOIN TICKET
ON CUSTOMER.ID_CUSTOMER = TICKET.ID_CUSTOMER
INNER JOIN SESSION
ON SESSION.ID_SESSION = TICKET.ID_SESSION
INNER JOIN FILM
ON SESSION.ID_FILM = FILM.ID_FILM
WHERE CUSTOMER.AGE < FILM.MIN_AGE;

--вывести для каждого фильма название и его среднюю оценку. Отсортировать в порядке убывания рейтинга--

SELECT FILM, CASE WHEN COUNT(REVIEW.MARK) = 0
             THEN 0
             ELSE AVG(REVIEW.MARK)
             END AS mark
FROM FILM
LEFT JOIN REVIEW
ON FILM.ID_FILM = REVIEW.ID_FILM
GROUP BY FILM
ORDER BY mark DESC;

--вывести всех людей, которые были в vip зале--

SELECT DISTINCT NAME
FROM CUSTOMER
INNER JOIN TICKET
ON CUSTOMER.ID_CUSTOMER = TICKET.ID_CUSTOMER
INNER JOIN SESSION
ON SESSION.ID_SESSION = TICKET.ID_SESSION
INNER JOIN HALL
ON HALL.ID_HALL = SESSION.ID_HALL
WHERE SPECIFICATION = 'vip';


--вывести людей, которые ходили в кино в разных городах--

SELECT DISTINCT CUSTOMER.NAME, count(DISTINCT CINEMA.NAME)
FROM CUSTOMER
INNER JOIN TICKET
ON CUSTOMER.ID_CUSTOMER = TICKET.ID_CUSTOMER
INNER JOIN SESSION
ON SESSION.ID_SESSION = TICKET.ID_SESSION
INNER JOIN HALL
ON HALL.ID_HALL = SESSION.ID_HALL
INNER JOIN CINEMA
ON CINEMA.ID_CINEMA = HALL.ID_CINEMA
GROUP BY CUSTOMER.NAME
HAVING count(DISTINCT CINEMA.NAME) > 1;

--Вьюшки--

--Удобно иметь иметь список вида кинотеатр/фильм--

CREATE TEMP VIEW FilmInCinema AS
  SELECT CINEMA.NAME, FILM.FILM
  FROM CINEMA
  INNER JOIN HALL
  ON HALL.ID_CINEMA = CINEMA.ID_CINEMA
  INNER JOIN SESSION
  ON SESSION.ID_HALL = HALL.ID_HALL
  INNER JOIN FILM
  ON FILM.ID_FILM = SESSION.ID_FILM;

--Скроем возраст зрителей--

CREATE TEMP VIEW CustomerWithoutAge AS
  SELECT CUSTOMER.ID_CUSTOMER, CUSTOMER.NAME
  FROM CUSTOMER;

--Список залов для кинотеатров-

CREATE TEMP VIEW HallInCinema AS
  SELECT CINEMA.NAME, HALL.HALL_NUM, HALL.SPECIFICATION
  FROM CINEMA
  INNER JOIN HALL
  ON HALL.ID_CINEMA = CINEMA.ID_CINEMA;

--Cоздание ролей--

CREATE ROLE viewer WITH
    LOGIN;

CREATE ROLE cashier WITH
    LOGIN;

GRANT SELECT ON TABLE CINEMA, HALL, FILM, SESSION, REVIEW TO viewer;
GRANT INSERT ON TABLE REVIEW TO viewer;

GRANT ALL PRIVILEGES ON TABLE TICKET, CUSTOMER TO cashier;
GRANT SELECT ON TABLE CINEMA, HALL, FILM, SESSION, TOTAL_INFO_TICKET_LOG, CINEMA_LIST TO cashier;
GRANT EXECUTE ON FUNCTION c_list(), log_ticket(), summary_ticket_insert(), summary_ticket_delete(), TAKE_CINEMA(INTEGER) TO cashier;
GRANT INSERT ON TABLE TOTAL_INFO_TICKET_LOG, CINEMA_LIST TO cashier;

--ФИНАЛЬНОЕ УДАЛЕНИЕ--

--SELECT * FROM CINEMA;
DROP TABLE IF EXISTS CINEMA CASCADE;
--SELECT * FROM HALL;
DROP TABLE IF EXISTS HALL CASCADE;
--SELECT * FROM FILM;
DROP TABLE IF EXISTS FILM CASCADE;
--SELECT * FROM SESSION;
DROP TABLE IF EXISTS SESSION CASCADE;
---SELECT * FROM CUSTOMER;
DROP TABLE IF EXISTS CUSTOMER CASCADE;
SELECT * FROM TICKET;
DROP TABLE IF EXISTS TICKET CASCADE;
--SELECT * FROM REVIEW;
DROP TABLE IF EXISTS REVIEW CASCADE;

DROP TABLE IF EXISTS TOTAL_INFO_TICKET_LOG CASCADE;
DROP FUNCTION IF EXISTS c_list() CASCADE;

DROP FUNCTION IF EXISTS log_ticket() CASCADE;
DROP FUNCTION IF EXISTS summary_ticket_insert() CASCADE;
DROP FUNCTION IF EXISTS summary_ticket_delete() CASCADE;
DROP FUNCTION IF EXISTS TAKE_CINEMA(ID_TICKET INTEGER) CASCADE;
DROP TABLE IF EXISTS CINEMA_LIST CASCADE;
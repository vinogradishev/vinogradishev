DROP DATABASE IF EXISTS "BookShop";
	
DO
$role$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'student')
	THEN
		CREATE ROLE student LOGIN
		  ENCRYPTED PASSWORD 'md550d9482e20934ce6df0bf28941f885bc'
		  NOSUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION;
	END IF;
END; 	
$role$;

CREATE DATABASE "BookShop"
  WITH OWNER = student
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8'
       CONNECTION LIMIT = -1;


COMMENT ON DATABASE "BookShop" IS
'Demo-DB для курсов
	"PostgreSQL: Уровень 1. Основы SQL"
	и
	"PostgreSQL: Уровень 2. Продвинутые возможности"
- рассматриваются возможности Pg на примере книжного ИМ';


\connect BookShop	-- выполняется только при выполнении скрипта в psql, в других клиентах - закомментировать
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
CREATE EXTENSION ltree SCHEMA public;
-----------------------------------------------------------------------------------------------------------------------------

-- DROP SCHEMA IF EXISTS book_store;
CREATE SCHEMA book_store AUTHORIZATION student;

COMMENT ON SCHEMA book_store IS 'Книги, авторы, тематический рубрикатор и всё прочее, связанное с книгами';
-----------------------------------------------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS book_store.genre;
CREATE TABLE book_store.genre
(
	genre_id	serial	PRIMARY KEY,
	parent		integer	NOT NULL DEFAULT currval('book_store.genre_genre_id_seq'::regclass)
						REFERENCES book_store.genre (genre_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	genre_code	ltree	NOT NULL,
	genre_name	varchar(511) NOT NULL UNIQUE
);
ALTER TABLE book_store.genre OWNER TO student;

CREATE INDEX i1_genre ON book_store.genre USING btree (parent);

COMMENT ON TABLE book_store.genre
IS 'Список жанров (этакий условный тематический рубрикатор)

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.genre.genre_id	IS 'Собственный идентификатор жанра';
COMMENT ON COLUMN book_store.genre.parent	IS 'Жанр-родитель';
COMMENT ON COLUMN book_store.genre.genre_code	IS 'Код жанра';
COMMENT ON COLUMN book_store.genre.genre_name	IS 'Наименование жанра';
-----------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE IF EXISTS book_store.book;
CREATE TABLE book_store.book
(
	book_id		serial 			PRIMARY KEY,
	book_name	varchar(255) 	NOT NULL,
	isbn		varchar(18) 	UNIQUE,
	published	smallint,
	genre_id	integer 		NOT NULL REFERENCES book_store.genre (genre_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);
ALTER TABLE book_store.book OWNER TO student;

CREATE INDEX i1_book ON book_store.book USING btree (genre_id);

COMMENT ON TABLE book_store.book
IS 'Rеквизиты книги

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.book.book_id	IS 'Собственный идентификатор книги';
COMMENT ON COLUMN book_store.book.book_name	IS 'Наименование книги';
COMMENT ON COLUMN book_store.book.isbn		IS 'ISBN - International Standart Book Number';
COMMENT ON COLUMN book_store.book.published	IS 'Год издания';
COMMENT ON COLUMN book_store.book.genre_id	IS 'Жанр';
-----------------------------------------------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS book_store.author;
CREATE TABLE book_store.author
(
	author_id	serial 		PRIMARY KEY,
	author_name	varchar(127) NOT NULL UNIQUE,
	biography	text
);
ALTER TABLE book_store.author OWNER TO student;

COMMENT ON TABLE book_store.author
IS 'Авторы книг

поле author_name не разбито на "имя - фамилия-отчество" по следующим причинам:
- у автора может отсутствовать не только отчество, но и деление на имя-фамилию (Сунь-Цзы, Геродот, etc)
- имени и фамилии может быть недостаточно, а отчества при этом может не быть (Александр Дюма отец и Александр Дюма сын)
- авторам мы ничего не выплачиваем (т.к. не издательство), нет формирования официальных (платёжных) документов - нет необходимости в официальном именовании 

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.author.author_id	IS 'Идентификатор автора';
COMMENT ON COLUMN book_store.author.author_name	IS 'Имя автора (полное!)';
COMMENT ON COLUMN book_store.author.biography	IS 'Краткая биография автора';
-----------------------------------------------------------------------------------------------------------------------------


-- DROP TABLE IF EXISTS book_store.book_author;
CREATE TABLE book_store.book_author
(
	book_id		integer NOT NULL REFERENCES book_store.book (book_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
	author_id	integer NOT NULL REFERENCES book_store.author (author_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	/*
	Каскадное удаление при удалении книги разрешено - в результате удалится книга, автор останется
	Удаление автора, с которым связано хотя бы одна книга - запрещено.
	*/
	CONSTRAINT pk_book_author PRIMARY KEY (book_id, author_id)
);
ALTER TABLE book_store.book_author OWNER TO student;

COMMENT ON TABLE book_store.book_author
IS 'Кросс-таблица для привязки авторов к книгам

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.book_author.book_id	IS 'Книга';
COMMENT ON COLUMN book_store.book_author.author_id	IS 'Автор';
-----------------------------------------------------------------------------------------------------------------------------



-- DROP TABLE IF EXISTS book_store.price_category;
CREATE TABLE book_store.price_category
(
	price_category_no	integer		PRIMARY KEY,
	category_name		varchar (63) NOT NULL UNIQUE
);
ALTER TABLE book_store.price_category OWNER TO student;

COMMENT ON TABLE book_store.price_category
IS 'Категории цен

	price_category_no - задаётся "руками"

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.price_category.price_category_no	IS 'Идентификатор (код) ценовой категории';
COMMENT ON COLUMN book_store.price_category.category_name		IS 'Наименование ценовой категории';
-----------------------------------------------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS book_store.price;
CREATE TABLE book_store.price
(
	price_id			serial 	PRIMARY KEY,
	book_id				integer NOT NULL REFERENCES book_store.book (book_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	price_category_no	integer NOT NULL REFERENCES book_store.price_category (price_category_no) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	price_value			numeric (8, 2) NOT NULL CHECK (price_value > 0),
	price_expired		date

	-- , CONSTRAINT uq_price UNIQUE (book_id, price_category_no)
);
ALTER TABLE book_store.price OWNER TO student;

CREATE INDEX i1_price ON book_store.price USING btree (book_id);
CREATE INDEX i2_price ON book_store.price USING btree (price_category_no);
CREATE UNIQUE INDEX uqix_price ON book_store.price USING btree (book_id, price_category_no, COALESCE(price_expired, '2221-01-01'::date));	-- временное решение!

COMMENT ON TABLE book_store.price
IS 'Цены

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.price.price_id				IS 'Идентификатор цены';
COMMENT ON COLUMN book_store.price.book_id				IS 'Книга, для которой определяется цена';
COMMENT ON COLUMN book_store.price.price_category_no	IS 'Категория цены';
COMMENT ON COLUMN book_store.price.price_value			IS 'Собственно цена';
COMMENT ON COLUMN book_store.price.price_expired		IS 'Дата окончания срока действия цены, для актуальной цены - NULL';
-----------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------
-- DROP SCHEMA IF EXISTS shop
CREATE SCHEMA shop AUTHORIZATION student;

COMMENT ON SCHEMA shop IS 'Клиенты и заказы';


-- DROP TABLE IF EXISTS shop.client;
CREATE TABLE shop.client
(
	-- client_id	serial PRIMARY KEY
	client_login	varchar(31) PRIMARY KEY,
	firstname		varchar(63) NOT NULL,
	lastname		varchar(63) NOT NULL,
	patronymic		varchar(63),
	email			varchar(511),
	phone			char(10),
	delivery_addr	varchar(767) NOT NULL,

	CONSTRAINT chk_client_attributes CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
ALTER TABLE shop.client OWNER TO student;

COMMENT ON TABLE shop.client
IS 'Список клиентов

	При регистрации клиент может не указывать отчество, имя и фамилия - обязательны.

	В реальной системе delivery_addr и phone скорее всего были бы вынесены в отдельные таблицы и бизнес-логика предусматривала бы
	возможность привязки к лиенту нескольких телефонных номеров (а может, и email) и нескольких адресов доставки (домашний, офисный, ...).
	Учебную базу упрощаем - только один телефон, только один адрес доставки.

	В реальной системе скорее всего был бы введён суррогатный ключ (см. закомментированный client_id), в учебной используем естественный,
	исключительно для демонстрации такой возможности. 

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

-- COMMENT ON COLUMN shop.client.client_id	IS 'Идентификатор клиента (суррогатный)';
COMMENT ON COLUMN shop.client.client_login	IS 'Login клиента';
COMMENT ON COLUMN shop.client.firstname		IS 'Имя клиента';
COMMENT ON COLUMN shop.client.lastname		IS 'Фамилия клиента';
COMMENT ON COLUMN shop.client.patronymic	IS 'Отчество клиента';
COMMENT ON COLUMN shop.client.email			IS 'Адрес e-mail клиента';
COMMENT ON COLUMN shop.client.phone			IS 'Контактный телефон клиента';
COMMENT ON COLUMN shop.client.delivery_addr	IS 'Адрес доставки';

COMMENT ON CONSTRAINT chk_client_attributes ON shop.client IS 'Хотя бы одно поле - email или phone должно быть заполнено';
-----------------------------------------------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS shop.order_main;
CREATE TABLE shop.order_main
(
	order_id		serial 		PRIMARY KEY,
	client_login	varchar(31)	NOT NULL REFERENCES shop.client (client_login) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	order_cnt		serial		NOT NULL,
	order_no		char(14) 	NOT NULL UNIQUE,
	order_date		date 		DEFAULT current_date
);
ALTER TABLE shop.order_main OWNER TO student;

COMMENT ON TABLE shop.order_main
IS 'Заказы
	Нзвание "order_main" а не "order" выбрано, чтобы избежать совпадений с ключевым словом языка SQL. 
Дата создания:	30.04.2020 (Admin)
Дата изменения:	
'; 	

COMMENT ON COLUMN shop.order_main.order_id		IS 'Идентификатор заказа';
COMMENT ON COLUMN shop.order_main.order_cnt		IS 'Служебное поле - целочисленный номер заказа в пределах года';
COMMENT ON COLUMN shop.order_main.order_no		IS 'Строковый номер заказа для печатных форм';
COMMENT ON COLUMN shop.order_main.order_date	IS 'Дата размещения заказа';
-----------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE IF EXISTS shop.order_detail;
CREATE TABLE shop.order_detail
(
	order_id	integer NOT NULL
						REFERENCES shop.order_main (order_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
	book_id		integer NOT NULL
						REFERENCES book_store.book (book_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
	qty			integer NOT NULL CHECK (qty >0 ),
	price_category_no	integer NOT NULL
						REFERENCES book_store.price_category (price_category_no) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT pk_order_detail PRIMARY KEY (order_id, book_id)
);
ALTER TABLE shop.order_detail OWNER TO student;

CREATE INDEX i1_order_detail ON shop.order_detail USING btree (price_category_no);		-- ???

COMMENT ON TABLE shop.order_detail
IS 'Детализация заказа

Дата создания:	30.04.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN shop.order_detail.order_id			IS 'Идентификатор заказа';
COMMENT ON COLUMN shop.order_detail.book_id				IS 'Книга';
COMMENT ON COLUMN shop.order_detail.qty					IS 'Количество экземпляров';
COMMENT ON COLUMN shop.order_detail.price_category_no	IS 'Какая категория цен применяется';
-----------------------------------------------------------------------------------------------------------------------------

-- Заполнение тематического рубрикатора, перечня авторов, каталога книг

/*
TRUNCATE TABLE book RESTART IDENTITY CASCADE;
TRUNCATE TABLE genre RESTART IDENTITY CASCADE;
TRUNCATE TABLE author RESTART IDENTITY CASCADE;
TRUNCATE TABLE price RESTART IDENTITY CASCADE;
TRUNCATE TABLE price_category RESTART IDENTITY CASCADE;
*/

START TRANSACTION;

SET search_path = book_store, public;

INSERT INTO price_category (price_category_no, category_name)
VALUES 	(1, 'Базовая цена'),
	(2, 'Цена VIP клиента'),
	(3, 'Цена по акции');


DO
$fill$
DECLARE
	historic_book_id	integer;
	biography_book_id	integer;
	historic_article_id	integer;
	historic_novels_id	integer;
	historic_fiction_id	integer;
	scientist_biography_id	integer;
	aero_biography_id	integer;
	techn_book_id		integer;
	poetry_id		integer;
	belles_lettres_id	integer;
	comp_book_id		integer;
	algolanguages_id	integer;
	databases_id		integer;

	last_author_id		integer;

BEGIN
	INSERT INTO genre (genre_name, genre_code)
	VALUES ('Историческая литература', '3')
	RETURNING genre_id INTO historic_book_id;
	
	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Мемуары и биографии', historic_book_id, '3.1')
	RETURNING genre_id INTO biography_book_id;
	
	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Исторические очерки', historic_book_id, '3.2')
	RETURNING genre_id INTO historic_article_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Очерки об анитчной истории', historic_article_id, '3.2.1');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Очерки о средневековье', historic_article_id, '3.2.2');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Очерки об истории эпохи возрождения', historic_article_id, '3.2.3');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Очерки о новейшей истории', historic_article_id, '3.2.4');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Исторические романы', historic_book_id, '3.3')
	RETURNING genre_id INTO historic_novels_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Историческая фантастика', historic_book_id, '3.4')
	RETURNING genre_id INTO historic_fiction_id;
	
	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Биографии художников и музыкантов', biography_book_id, '3.1.1');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Биографии путешественников', biography_book_id, '3.1.3');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Биографии инженеров и ученых', biography_book_id, '3.1.2')
	RETURNING genre_id INTO scientist_biography_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Биографии авиакострукторов', scientist_biography_id, '3.1.2.1')
	RETURNING genre_id INTO aero_biography_id;

	INSERT INTO genre (genre_name, genre_code)
	VALUES ('Художественная литература', '4')
	RETURNING genre_id INTO belles_lettres_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Поэзия', belles_lettres_id, '4.1');

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Проза', belles_lettres_id, '4.2')
	RETURNING genre_id INTO poetry_id;
	
	INSERT INTO genre (genre_name, genre_code)
	VALUES ('Техническая литература', '5')
	RETURNING genre_id INTO techn_book_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Компьютеры и программирование', techn_book_id, '5.1')
	RETURNING genre_id INTO comp_book_id;
		
	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Языки программирования', comp_book_id, '5.1.1')
	RETURNING genre_id INTO algolanguages_id;

	INSERT INTO genre (genre_name, parent, genre_code)
	VALUES ('Базы данных', comp_book_id, '5.1.2')
	RETURNING genre_id INTO databases_id;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Роберт Уолтерс'),
			('Майкл Коулс'),
			('Фабио Клаудио Феррачати'),
			('Роберт Рей'),
			('Дональд Фармер')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES 	('978-5-8459-1481-1', 'SQL Server 2008. Ускоренный курс для профессионалов', algolanguages_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 1610. FROM  bk
		UNION
		SELECT book_id, 2, 1670 FROM  bk
		UNION
		SELECT book_id, 3, 1499.99 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Кристофер Дж. Дейт')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES ('5-8459-0788-8', 'Введение в системы баз данных', algolanguages_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 1840.50 FROM  bk
		UNION
		SELECT book_id, 2, 1800 FROM  bk
		UNION
		SELECT book_id, 3, 1800 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Бьёрн Страуструп')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES ('978-5-7989-0226-2', 'Язык программирования С++. Специальное издание', algolanguages_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 1600 FROM  bk
		UNION
		SELECT book_id, 2, 1450.50 FROM  bk
		UNION
		SELECT book_id, 3, 10400 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;
	
	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('В.Р.Михеев'),
			('Г.И.Катышев')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES ('5-7325-0564-4', 'Сикорский', aero_biography_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 960.50 FROM  bk
		UNION
		SELECT book_id, 2, 900 FROM  bk
		UNION
		SELECT book_id, 3, 850 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Феликс Чуев')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES ('978-5-235-03285-9', 'Ильюшин', aero_biography_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 450.50 FROM  bk
		UNION
		SELECT book_id, 2, 400 FROM  bk
		UNION
		SELECT book_id, 3, 350 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('А.Н.Пономарев')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES ('5-203-00139-1', 'Конструктор С.В.Ильюшин', aero_biography_id)
		RETURNING book_id
		)
	, prc
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 475 FROM  bk
		UNION
		SELECT book_id, 2, 430 FROM  bk
		UNION
		SELECT book_id, 3, 400 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Леонид Анциелович')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES 	('978-5-699-49800-0', 'Неизвестный Хейнкель', aero_biography_id),
			('978-5-699-58507-6', 'Неизвестный Юнкерс', aero_biography_id)
		RETURNING book_id
		)
	, prc		-- на обе книги ставим одинаковые цены
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 465 FROM  bk
		UNION
		SELECT book_id, 2, 440 FROM  bk
		UNION
		SELECT book_id, 3, 410 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

	WITH auth
	AS	(
		INSERT INTO author (author_name)
		VALUES	('Мартин Фаулер')
		RETURNING author_id
		)
	, bk
	AS	(
		INSERT INTO book (isbn, book_name, genre_id)
		VALUES 	('5-93286-045-6', 'Рефакторинг. Улучшение существующего кода', comp_book_id)
		RETURNING book_id
		)
	, prc		-- Только 2 цены!
	AS	(
		INSERT INTO price (book_id, price_category_no, price_value)
		SELECT book_id, 1, 590 FROM  bk
		UNION
		SELECT book_id, 3, 520.50 FROM  bk
		)
	INSERT INTO book_author (author_id, book_id)
	SELECT A.author_id, B.book_id
	FROM auth A, bk B;

END;
$fill$;

COMMIT;

START TRANSACTION;

INSERT INTO shop.client (client_login, firstname, patronymic, lastname, email, phone, delivery_addr)
VALUES	('Ivan IV', 'Иван', 'Васильевич', ' Рюрик', 'Ivan_The_Terrible@postbox.ru', '4992223344', 'Московская область, г.Балашиха, Пригородная улица, 11'),
	('Peter I', 'Пётр', 'Алексеевич', 'Романов', 'peter the_great@gnail.com', '4995553344', 'Москва, Просторная улица д.9, кв.25'),
	('Марк Твен', 'Сэмюэл', NULL, 'Клеменс', 'mark_twain@gmail.com', '4991234566', 'Москва, улица Обручева д.22, кв.42'),
	('Lyric', 'Михаил', 'Юрьевич', 'Лермонтов', 'poetry@list.ru', '4997770044', 'Москва, 3я Рыбинская улица 18с2, кв.11'),
	('Itsme', 'Антон', 'Владимирович', 'Золотов', 'av_zolotov@list.ru', '4999873124', 'Москва, 6-й Красносельский переулок д.3'),
	('Alex', 'Александр', NULL, 'Александров', 'aa_forever@yandex.ru', '4999877731', 'Москва, Ленинский проспект д.107, офис 4'),
	('Serge', 'Сергей', '', 'Сергеев', NULL, '4952003344', 'Москва, проспект Вернадского, 61к2 кв. 71'),
	('O''Henry', 'William Sydney', NULL, 'Porter', 'o_henry@gmail.com', '4952880000', 'Москва, Мичуринский проспект, 9к4, кв. 41'),
	('Stasy', 'Анастасия', '', 'Петровна', NULL, '4959999999', 'Москва, улица Красная Пресня, 44с2, кв.2'),
	('Т Ларина', 'Татьяна', '', 'Ларина', 'larina@mail.ru', '4957403344', 'Москва, Башиловская улица, д.3к1, кв.81'),
	('О Ларина', 'Ольга', '', 'Ларина', 'larina@yandex.ru', '4957413344', 'Москва, Новоалексеевская улица д.1, кв.3'),
	('mpd', 'Мария', 'Петровна', 'Денисова', NULL, '4952223344', 'Москва, проезд Серебрякова д.6с1, кв.32'),
	('Joury', 'Юрий', NULL, '', 'youriy_youriy@tochka.ru', '4957423344', 'Московская область, Мытищи, Хлебозаводская улица д.4с3, кв.2'),
	('Nowhere Man', '', NULL,'Семёнов', NULL, '4957643344', 'Московская область, Щёлково, Комсомольская улица д.3, кв.5');

TRUNCATE TABLE shop.order_main RESTART IDENTITY CASCADE; 
--
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (2, 'Ivan IV', 2, '00002/2020-mar', '2020-03-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (3, 'Ivan IV', 3, '00003/2020-feb', '2020-02-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (4, 'Ivan IV', 4, '00004/2019-aug', '2019-08-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (5, 'Ivan IV', 5, '00005/2020-apr', '2020-04-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (6, 'Ivan IV', 6, '00006/2019-oct', '2019-10-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (7, 'Ivan IV', 7, '00007/2020-jan', '2020-01-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (9, 'Ivan IV', 9, '00009/2019-aug', '2019-08-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (10, 'Ivan IV', 10, '00010/2020-jan', '2020-01-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (11, 'Ivan IV', 11, '00011/2019-jul', '2019-07-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (13, 'Ivan IV', 13, '00013/2019-may', '2019-05-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (14, 'Ivan IV', 14, '00014/2019-nov', '2019-11-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (15, 'Ivan IV', 15, '00015/2020-jan', '2020-01-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (16, 'Ivan IV', 16, '00016/2019-sep', '2019-09-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (17, 'Ivan IV', 17, '00017/2020-jan', '2020-01-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (19, 'Ivan IV', 19, '00019/2019-jun', '2019-06-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (20, 'Ivan IV', 20, '00020/2020-feb', '2020-02-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (22, 'Ivan IV', 22, '00022/2020-mar', '2020-03-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (23, 'Ivan IV', 23, '00023/2020-feb', '2020-02-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (24, 'Ivan IV', 24, '00024/2020-mar', '2020-03-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (25, 'Ivan IV', 25, '00025/2020-mar', '2020-03-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (26, 'Ivan IV', 26, '00026/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (27, 'Ivan IV', 27, '00027/2019-nov', '2019-11-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (28, 'Ivan IV', 28, '00028/2019-aug', '2019-08-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (30, 'Ivan IV', 30, '00030/2020-jan', '2020-01-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (31, 'Ivan IV', 31, '00031/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (32, 'Ivan IV', 32, '00032/2019-sep', '2019-09-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (33, 'Ivan IV', 33, '00033/2020-feb', '2020-02-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (34, 'Ivan IV', 34, '00034/2020-mar', '2020-03-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (35, 'Ivan IV', 35, '00035/2019-jun', '2019-06-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (36, 'Ivan IV', 36, '00036/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (37, 'Ivan IV', 37, '00037/2019-dec', '2019-12-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (40, 'Ivan IV', 40, '00040/2019-oct', '2019-10-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (41, 'Ivan IV', 41, '00041/2019-oct', '2019-10-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (42, 'Ivan IV', 42, '00042/2019-nov', '2019-11-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (44, 'Ivan IV', 44, '00044/2020-mar', '2020-03-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (45, 'Ivan IV', 45, '00045/2019-jul', '2019-07-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (46, 'Ivan IV', 46, '00046/2020-jan', '2020-01-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (48, 'Ivan IV', 48, '00048/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (50, 'Ivan IV', 50, '00050/2019-oct', '2019-10-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (51, 'Ivan IV', 51, '00051/2019-dec', '2019-12-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (52, 'Ivan IV', 52, '00052/2019-nov', '2019-11-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (53, 'Ivan IV', 53, '00053/2019-oct', '2019-10-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (54, 'Ivan IV', 54, '00054/2019-dec', '2019-12-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (55, 'Ivan IV', 55, '00055/2019-dec', '2019-12-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (56, 'Ivan IV', 56, '00056/2019-oct', '2019-10-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (58, 'Ivan IV', 58, '00058/2019-jul', '2019-07-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (59, 'Ivan IV', 59, '00059/2020-apr', '2020-04-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (60, 'Ivan IV', 60, '00060/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (61, 'Ivan IV', 61, '00061/2020-mar', '2020-03-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (62, 'Ivan IV', 62, '00062/2020-feb', '2020-02-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (63, 'Ivan IV', 63, '00063/2020-mar', '2020-03-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (64, 'Ivan IV', 64, '00064/2019-aug', '2019-08-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (65, 'Ivan IV', 65, '00065/2019-sep', '2019-09-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (66, 'Ivan IV', 66, '00066/2019-may', '2019-05-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (67, 'Ivan IV', 67, '00067/2020-apr', '2020-04-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (68, 'Ivan IV', 68, '00068/2019-jun', '2019-06-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (70, 'Ivan IV', 70, '00070/2019-sep', '2019-09-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (72, 'Ivan IV', 72, '00072/2019-dec', '2019-12-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (73, 'Ivan IV', 73, '00073/2019-may', '2019-05-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (74, 'Peter I', 74, '00074/2019-nov', '2019-11-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (75, 'Peter I', 75, '00075/2019-dec', '2019-12-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (76, 'Peter I', 76, '00076/2019-dec', '2019-12-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (77, 'Peter I', 77, '00077/2019-jul', '2019-07-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (78, 'Peter I', 78, '00078/2020-apr', '2020-04-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (79, 'Peter I', 79, '00079/2020-jan', '2020-01-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (80, 'Peter I', 80, '00080/2019-nov', '2019-11-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (81, 'Peter I', 81, '00081/2020-feb', '2020-02-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (82, 'Peter I', 82, '00082/2019-oct', '2019-10-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (83, 'Peter I', 83, '00083/2020-jan', '2020-01-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (84, 'Peter I', 84, '00084/2020-mar', '2020-03-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (85, 'Peter I', 85, '00085/2019-may', '2019-05-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (86, 'Peter I', 86, '00086/2019-oct', '2019-10-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (87, 'Peter I', 87, '00087/2019-may', '2019-05-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (88, 'Peter I', 88, '00088/2019-aug', '2019-08-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (89, 'Peter I', 89, '00089/2019-jul', '2019-07-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (90, 'Peter I', 90, '00090/2019-jul', '2019-07-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (91, 'Peter I', 91, '00091/2019-oct', '2019-10-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (92, 'Peter I', 92, '00092/2019-oct', '2019-10-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (93, 'Peter I', 93, '00093/2019-dec', '2019-12-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (94, 'Peter I', 94, '00094/2019-jun', '2019-06-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (95, 'Peter I', 95, '00095/2019-aug', '2019-08-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (96, 'Peter I', 96, '00096/2019-aug', '2019-08-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (97, 'Peter I', 97, '00097/2020-feb', '2020-02-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (98, 'Peter I', 98, '00098/2019-oct', '2019-10-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (99, 'Peter I', 99, '00099/2019-may', '2019-05-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (100, 'Peter I', 100, '00100/2020-feb', '2020-02-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (101, 'Peter I', 101, '00101/2019-sep', '2019-09-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (102, 'Peter I', 102, '00102/2020-apr', '2020-04-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (103, 'Peter I', 103, '00103/2019-nov', '2019-11-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (104, 'Peter I', 104, '00104/2020-jan', '2020-01-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (105, 'Peter I', 105, '00105/2020-jan', '2020-01-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (106, 'Peter I', 106, '00106/2020-mar', '2020-03-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (107, 'Peter I', 107, '00107/2019-jul', '2019-07-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (108, 'Peter I', 108, '00108/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (109, 'Peter I', 109, '00109/2019-dec', '2019-12-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (110, 'Peter I', 110, '00110/2020-jan', '2020-01-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (111, 'Peter I', 111, '00111/2019-sep', '2019-09-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (112, 'Peter I', 112, '00112/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (113, 'Peter I', 113, '00113/2019-jun', '2019-06-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (114, 'Peter I', 114, '00114/2020-jan', '2020-01-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (115, 'Peter I', 115, '00115/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (116, 'Peter I', 116, '00116/2019-nov', '2019-11-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (117, 'Peter I', 117, '00117/2019-jun', '2019-06-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (118, 'Peter I', 118, '00118/2020-mar', '2020-03-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (119, 'Peter I', 119, '00119/2020-jan', '2020-01-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (120, 'Peter I', 120, '00120/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (121, 'Peter I', 121, '00121/2019-dec', '2019-12-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (122, 'Peter I', 122, '00122/2019-sep', '2019-09-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (123, 'Peter I', 123, '00123/2020-apr', '2020-04-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (124, 'Peter I', 124, '00124/2019-aug', '2019-08-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (125, 'Peter I', 125, '00125/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (126, 'Peter I', 126, '00126/2019-may', '2019-05-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (127, 'Peter I', 127, '00127/2020-jan', '2020-01-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (128, 'Peter I', 128, '00128/2019-nov', '2019-11-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (129, 'Peter I', 129, '00129/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (130, 'Peter I', 130, '00130/2019-jul', '2019-07-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (131, 'Peter I', 131, '00131/2019-nov', '2019-11-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (132, 'Peter I', 132, '00132/2019-sep', '2019-09-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (133, 'Peter I', 133, '00133/2019-may', '2019-05-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (134, 'Peter I', 134, '00134/2020-feb', '2020-02-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (135, 'Peter I', 135, '00135/2019-sep', '2019-09-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (136, 'Peter I', 136, '00136/2020-mar', '2020-03-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (137, 'Peter I', 137, '00137/2019-jul', '2019-07-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (138, 'Марк Твен', 138, '00138/2019-oct', '2019-10-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (141, 'Марк Твен', 141, '00141/2019-sep', '2019-09-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (142, 'Марк Твен', 142, '00142/2019-nov', '2019-11-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (143, 'Марк Твен', 143, '00143/2019-nov', '2019-11-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (144, 'Марк Твен', 144, '00144/2019-oct', '2019-10-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (145, 'Марк Твен', 145, '00145/2020-feb', '2020-02-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (146, 'Марк Твен', 146, '00146/2020-mar', '2020-03-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (147, 'Марк Твен', 147, '00147/2020-mar', '2020-03-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (149, 'Марк Твен', 149, '00149/2019-sep', '2019-09-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (151, 'Марк Твен', 151, '00151/2020-may', '2020-05-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (153, 'Марк Твен', 153, '00153/2020-jan', '2020-01-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (155, 'Марк Твен', 155, '00155/2019-may', '2019-05-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (160, 'Марк Твен', 160, '00160/2019-oct', '2019-10-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (161, 'Марк Твен', 161, '00161/2019-nov', '2019-11-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (163, 'Марк Твен', 163, '00163/2019-jun', '2019-06-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (164, 'Марк Твен', 164, '00164/2020-jan', '2020-01-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (166, 'Марк Твен', 166, '00166/2019-nov', '2019-11-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (167, 'Марк Твен', 167, '00167/2020-mar', '2020-03-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (168, 'Марк Твен', 168, '00168/2019-jun', '2019-06-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (169, 'Марк Твен', 169, '00169/2020-mar', '2020-03-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (170, 'Марк Твен', 170, '00170/2020-feb', '2020-02-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (172, 'Марк Твен', 172, '00172/2019-aug', '2019-08-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (175, 'Марк Твен', 175, '00175/2019-aug', '2019-08-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (177, 'Марк Твен', 177, '00177/2019-nov', '2019-11-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (178, 'Марк Твен', 178, '00178/2019-jun', '2019-06-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (181, 'Lyric', 181, '00181/2020-apr', '2020-04-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (182, 'Lyric', 182, '00182/2019-nov', '2019-11-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (183, 'Lyric', 183, '00183/2019-sep', '2019-09-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (184, 'Lyric', 184, '00184/2019-jul', '2019-07-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (185, 'Lyric', 185, '00185/2020-feb', '2020-02-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (186, 'Lyric', 186, '00186/2019-sep', '2019-09-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (187, 'Lyric', 187, '00187/2019-jun', '2019-06-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (188, 'Lyric', 188, '00188/2019-aug', '2019-08-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (189, 'Lyric', 189, '00189/2019-nov', '2019-11-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (190, 'Lyric', 190, '00190/2019-dec', '2019-12-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (191, 'Lyric', 191, '00191/2019-oct', '2019-10-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (192, 'Lyric', 192, '00192/2020-may', '2020-05-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (193, 'Lyric', 193, '00193/2019-jul', '2019-07-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (194, 'Lyric', 194, '00194/2019-may', '2019-05-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (195, 'Lyric', 195, '00195/2019-aug', '2019-08-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (196, 'Lyric', 196, '00196/2020-feb', '2020-02-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (197, 'Lyric', 197, '00197/2019-may', '2019-05-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (198, 'Lyric', 198, '00198/2020-mar', '2020-03-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (199, 'Lyric', 199, '00199/2020-apr', '2020-04-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (200, 'Lyric', 200, '00200/2019-aug', '2019-08-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (201, 'Lyric', 201, '00201/2020-jan', '2020-01-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (202, 'Lyric', 202, '00202/2019-oct', '2019-10-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (203, 'Lyric', 203, '00203/2019-jul', '2019-07-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (204, 'Lyric', 204, '00204/2019-dec', '2019-12-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (205, 'Lyric', 205, '00205/2020-feb', '2020-02-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (206, 'Lyric', 206, '00206/2020-may', '2020-05-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (207, 'Lyric', 207, '00207/2019-nov', '2019-11-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (208, 'Lyric', 208, '00208/2020-mar', '2020-03-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (209, 'Lyric', 209, '00209/2019-nov', '2019-11-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (210, 'Lyric', 210, '00210/2019-jul', '2019-07-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (211, 'Lyric', 211, '00211/2020-apr', '2020-04-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (212, 'Lyric', 212, '00212/2020-apr', '2020-04-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (213, 'Lyric', 213, '00213/2020-feb', '2020-02-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (214, 'Lyric', 214, '00214/2020-mar', '2020-03-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (215, 'Lyric', 215, '00215/2019-aug', '2019-08-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (216, 'Lyric', 216, '00216/2019-nov', '2019-11-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (217, 'Lyric', 217, '00217/2020-feb', '2020-02-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (218, 'Lyric', 218, '00218/2019-may', '2019-05-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (219, 'Lyric', 219, '00219/2020-mar', '2020-03-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (220, 'Lyric', 220, '00220/2019-aug', '2019-08-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (221, 'Lyric', 221, '00221/2020-apr', '2020-04-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (222, 'Lyric', 222, '00222/2020-mar', '2020-03-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (223, 'Lyric', 223, '00223/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (224, 'Lyric', 224, '00224/2019-aug', '2019-08-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (225, 'Lyric', 225, '00225/2019-oct', '2019-10-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (226, 'Lyric', 226, '00226/2019-jun', '2019-06-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (227, 'Lyric', 227, '00227/2019-nov', '2019-11-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (228, 'Lyric', 228, '00228/2019-nov', '2019-11-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (229, 'Lyric', 229, '00229/2020-jan', '2020-01-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (230, 'Lyric', 230, '00230/2020-feb', '2020-02-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (231, 'Lyric', 231, '00231/2019-dec', '2019-12-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (232, 'Lyric', 232, '00232/2020-apr', '2020-04-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (233, 'Lyric', 233, '00233/2020-feb', '2020-02-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (234, 'Lyric', 234, '00234/2019-sep', '2019-09-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (235, 'Lyric', 235, '00235/2020-feb', '2020-02-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (236, 'Lyric', 236, '00236/2019-oct', '2019-10-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (237, 'Lyric', 237, '00237/2019-aug', '2019-08-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (238, 'Lyric', 238, '00238/2019-may', '2019-05-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (239, 'Lyric', 239, '00239/2019-aug', '2019-08-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (240, 'Lyric', 240, '00240/2020-apr', '2020-04-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (241, 'Lyric', 241, '00241/2019-nov', '2019-11-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (242, 'Lyric', 242, '00242/2019-aug', '2019-08-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (243, 'Lyric', 243, '00243/2020-may', '2020-05-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (244, 'Lyric', 244, '00244/2019-jun', '2019-06-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (245, 'Lyric', 245, '00245/2019-aug', '2019-08-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (246, 'Lyric', 246, '00246/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (247, 'Lyric', 247, '00247/2020-apr', '2020-04-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (248, 'Itsme', 248, '00248/2019-jul', '2019-07-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (249, 'Itsme', 249, '00249/2019-aug', '2019-08-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (250, 'Itsme', 250, '00250/2020-feb', '2020-02-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (251, 'Itsme', 251, '00251/2020-feb', '2020-02-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (252, 'Itsme', 252, '00252/2020-jan', '2020-01-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (253, 'Itsme', 253, '00253/2019-sep', '2019-09-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (254, 'Itsme', 254, '00254/2019-aug', '2019-08-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (255, 'Itsme', 255, '00255/2020-jan', '2020-01-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (256, 'Itsme', 256, '00256/2020-may', '2020-05-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (257, 'Itsme', 257, '00257/2020-apr', '2020-04-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (258, 'Itsme', 258, '00258/2019-nov', '2019-11-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (259, 'Itsme', 259, '00259/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (260, 'Itsme', 260, '00260/2019-may', '2019-05-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (261, 'Itsme', 261, '00261/2019-nov', '2019-11-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (262, 'Itsme', 262, '00262/2019-oct', '2019-10-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (263, 'Itsme', 263, '00263/2019-jun', '2019-06-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (264, 'Itsme', 264, '00264/2019-jun', '2019-06-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (265, 'Itsme', 265, '00265/2020-may', '2020-05-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (266, 'Itsme', 266, '00266/2020-feb', '2020-02-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (267, 'Itsme', 267, '00267/2020-jan', '2020-01-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (268, 'Itsme', 268, '00268/2020-mar', '2020-03-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (269, 'Itsme', 269, '00269/2019-dec', '2019-12-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (270, 'Itsme', 270, '00270/2019-oct', '2019-10-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (271, 'Itsme', 271, '00271/2019-nov', '2019-11-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (272, 'Itsme', 272, '00272/2020-mar', '2020-03-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (273, 'Itsme', 273, '00273/2019-may', '2019-05-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (274, 'Itsme', 274, '00274/2019-may', '2019-05-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (275, 'Itsme', 275, '00275/2019-dec', '2019-12-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (276, 'Itsme', 276, '00276/2020-mar', '2020-03-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (277, 'Itsme', 277, '00277/2019-oct', '2019-10-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (278, 'Itsme', 278, '00278/2019-dec', '2019-12-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (279, 'Itsme', 279, '00279/2020-jan', '2020-01-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (280, 'Itsme', 280, '00280/2019-aug', '2019-08-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (281, 'Itsme', 281, '00281/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (282, 'Itsme', 282, '00282/2019-dec', '2019-12-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (283, 'Itsme', 283, '00283/2019-sep', '2019-09-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (284, 'Itsme', 284, '00284/2020-apr', '2020-04-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (285, 'Itsme', 285, '00285/2020-apr', '2020-04-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (286, 'Itsme', 286, '00286/2020-apr', '2020-04-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (287, 'Itsme', 287, '00287/2019-dec', '2019-12-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (288, 'Itsme', 288, '00288/2020-jan', '2020-01-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (289, 'Itsme', 289, '00289/2020-may', '2020-05-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (290, 'Itsme', 290, '00290/2019-nov', '2019-11-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (291, 'Itsme', 291, '00291/2019-dec', '2019-12-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (292, 'Itsme', 292, '00292/2019-aug', '2019-08-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (293, 'Itsme', 293, '00293/2019-aug', '2019-08-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (294, 'Itsme', 294, '00294/2019-nov', '2019-11-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (295, 'Itsme', 295, '00295/2019-aug', '2019-08-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (296, 'Itsme', 296, '00296/2019-nov', '2019-11-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (297, 'Itsme', 297, '00297/2019-oct', '2019-10-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (298, 'Itsme', 298, '00298/2019-jul', '2019-07-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (299, 'Itsme', 299, '00299/2019-jun', '2019-06-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (300, 'Itsme', 300, '00300/2019-jul', '2019-07-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (301, 'Itsme', 301, '00301/2019-jun', '2019-06-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (302, 'Itsme', 302, '00302/2019-jul', '2019-07-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (303, 'Itsme', 303, '00303/2020-jan', '2020-01-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (304, 'Itsme', 304, '00304/2020-feb', '2020-02-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (305, 'Itsme', 305, '00305/2019-jun', '2019-06-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (306, 'Itsme', 306, '00306/2019-jul', '2019-07-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (307, 'Itsme', 307, '00307/2020-mar', '2020-03-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (308, 'Itsme', 308, '00308/2019-dec', '2019-12-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (309, 'Itsme', 309, '00309/2019-aug', '2019-08-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (310, 'Itsme', 310, '00310/2019-nov', '2019-11-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (311, 'Itsme', 311, '00311/2020-feb', '2020-02-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (312, 'Itsme', 312, '00312/2020-jan', '2020-01-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (314, 'Alex', 314, '00314/2019-dec', '2019-12-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (315, 'Alex', 315, '00315/2020-apr', '2020-04-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (316, 'Alex', 316, '00316/2020-feb', '2020-02-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (318, 'Alex', 318, '00318/2019-aug', '2019-08-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (322, 'Alex', 322, '00322/2019-nov', '2019-11-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (323, 'Alex', 323, '00323/2020-mar', '2020-03-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (324, 'Alex', 324, '00324/2019-jul', '2019-07-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (325, 'Alex', 325, '00325/2019-dec', '2019-12-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (326, 'Alex', 326, '00326/2020-mar', '2020-03-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (327, 'Alex', 327, '00327/2020-apr', '2020-04-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (330, 'Alex', 330, '00330/2019-jul', '2019-07-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (334, 'Alex', 334, '00334/2020-feb', '2020-02-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (336, 'Alex', 336, '00336/2019-may', '2019-05-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (339, 'Alex', 339, '00339/2019-sep', '2019-09-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (342, 'Alex', 342, '00342/2020-jan', '2020-01-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (343, 'Alex', 343, '00343/2019-oct', '2019-10-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (344, 'Alex', 344, '00344/2019-dec', '2019-12-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (348, 'Alex', 348, '00348/2020-jan', '2020-01-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (349, 'Alex', 349, '00349/2020-mar', '2020-03-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (350, 'Alex', 350, '00350/2019-sep', '2019-09-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (351, 'Alex', 351, '00351/2020-feb', '2020-02-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (352, 'Alex', 352, '00352/2020-feb', '2020-02-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (353, 'Alex', 353, '00353/2019-jul', '2019-07-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (355, 'Alex', 355, '00355/2019-aug', '2019-08-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (356, 'Alex', 356, '00356/2020-feb', '2020-02-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (357, 'Alex', 357, '00357/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (358, 'Alex', 358, '00358/2019-jul', '2019-07-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (360, 'Alex', 360, '00360/2019-jun', '2019-06-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (361, 'Alex', 361, '00361/2019-nov', '2019-11-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (363, 'Alex', 363, '00363/2019-aug', '2019-08-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (364, 'Alex', 364, '00364/2020-jan', '2020-01-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (368, 'Alex', 368, '00368/2019-nov', '2019-11-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (370, 'Alex', 370, '00370/2019-nov', '2019-11-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (372, 'Alex', 372, '00372/2020-apr', '2020-04-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (374, 'Alex', 374, '00374/2019-jun', '2019-06-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (375, 'Alex', 375, '00375/2019-sep', '2019-09-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (376, 'Alex', 376, '00376/2020-apr', '2020-04-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (379, 'Alex', 379, '00379/2019-oct', '2019-10-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (381, 'Alex', 381, '00381/2019-jun', '2019-06-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (382, 'Alex', 382, '00382/2020-mar', '2020-03-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (384, 'Alex', 384, '00384/2020-may', '2020-05-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (385, 'Alex', 385, '00385/2020-feb', '2020-02-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (388, 'Alex', 388, '00388/2019-oct', '2019-10-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (389, 'Alex', 389, '00389/2020-mar', '2020-03-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (390, 'Alex', 390, '00390/2019-jun', '2019-06-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (391, 'Alex', 391, '00391/2020-mar', '2020-03-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (392, 'Alex', 392, '00392/2019-jul', '2019-07-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (393, 'Serge', 393, '00393/2020-apr', '2020-04-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (394, 'Serge', 394, '00394/2020-feb', '2020-02-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (395, 'Serge', 395, '00395/2019-jul', '2019-07-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (396, 'Serge', 396, '00396/2019-oct', '2019-10-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (397, 'Serge', 397, '00397/2019-may', '2019-05-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (398, 'Serge', 398, '00398/2019-aug', '2019-08-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (399, 'Serge', 399, '00399/2019-jun', '2019-06-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (400, 'Serge', 400, '00400/2020-feb', '2020-02-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (401, 'Serge', 401, '00401/2019-aug', '2019-08-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (402, 'Serge', 402, '00402/2020-feb', '2020-02-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (403, 'Serge', 403, '00403/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (404, 'Serge', 404, '00404/2019-sep', '2019-09-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (405, 'Serge', 405, '00405/2020-may', '2020-05-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (406, 'Serge', 406, '00406/2019-aug', '2019-08-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (407, 'Serge', 407, '00407/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (408, 'Serge', 408, '00408/2020-jan', '2020-01-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (409, 'Serge', 409, '00409/2019-dec', '2019-12-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (410, 'Serge', 410, '00410/2020-apr', '2020-04-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (411, 'Serge', 411, '00411/2019-nov', '2019-11-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (412, 'Serge', 412, '00412/2020-feb', '2020-02-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (413, 'Serge', 413, '00413/2020-apr', '2020-04-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (414, 'Serge', 414, '00414/2020-jan', '2020-01-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (415, 'Serge', 415, '00415/2020-apr', '2020-04-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (416, 'Serge', 416, '00416/2020-feb', '2020-02-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (417, 'Serge', 417, '00417/2019-aug', '2019-08-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (418, 'Serge', 418, '00418/2020-apr', '2020-04-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (419, 'Serge', 419, '00419/2019-jul', '2019-07-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (420, 'Serge', 420, '00420/2020-apr', '2020-04-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (421, 'Serge', 421, '00421/2019-jun', '2019-06-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (422, 'Serge', 422, '00422/2020-apr', '2020-04-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (423, 'Serge', 423, '00423/2019-nov', '2019-11-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (424, 'Serge', 424, '00424/2019-oct', '2019-10-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (425, 'Serge', 425, '00425/2019-jun', '2019-06-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (426, 'Serge', 426, '00426/2019-oct', '2019-10-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (427, 'Serge', 427, '00427/2020-jan', '2020-01-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (428, 'Serge', 428, '00428/2019-sep', '2019-09-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (429, 'Serge', 429, '00429/2020-mar', '2020-03-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (430, 'Serge', 430, '00430/2020-jan', '2020-01-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (431, 'Serge', 431, '00431/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (432, 'Serge', 432, '00432/2019-dec', '2019-12-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (433, 'Serge', 433, '00433/2019-oct', '2019-10-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (434, 'Serge', 434, '00434/2019-dec', '2019-12-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (435, 'Serge', 435, '00435/2020-may', '2020-05-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (436, 'Serge', 436, '00436/2019-sep', '2019-09-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (437, 'Serge', 437, '00437/2020-feb', '2020-02-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (438, 'Serge', 438, '00438/2020-jan', '2020-01-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (439, 'Serge', 439, '00439/2019-nov', '2019-11-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (440, 'Serge', 440, '00440/2019-nov', '2019-11-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (441, 'Serge', 441, '00441/2019-jun', '2019-06-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (442, 'Serge', 442, '00442/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (443, 'Serge', 443, '00443/2019-jun', '2019-06-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (444, 'Serge', 444, '00444/2019-sep', '2019-09-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (445, 'Serge', 445, '00445/2020-mar', '2020-03-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (446, 'Serge', 446, '00446/2019-aug', '2019-08-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (447, 'Serge', 447, '00447/2019-oct', '2019-10-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (448, 'Serge', 448, '00448/2019-sep', '2019-09-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (449, 'Serge', 449, '00449/2019-sep', '2019-09-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (450, 'Serge', 450, '00450/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (451, 'Serge', 451, '00451/2019-oct', '2019-10-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (452, 'Serge', 452, '00452/2019-jul', '2019-07-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (453, 'Serge', 453, '00453/2019-dec', '2019-12-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (454, 'Serge', 454, '00454/2020-apr', '2020-04-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (455, 'Serge', 455, '00455/2019-jul', '2019-07-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (456, 'Serge', 456, '00456/2019-jul', '2019-07-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (457, 'Serge', 457, '00457/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (458, 'Serge', 458, '00458/2020-feb', '2020-02-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (459, 'Serge', 459, '00459/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (460, 'Serge', 460, '00460/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (461, 'Serge', 461, '00461/2020-apr', '2020-04-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (462, 'Serge', 462, '00462/2020-mar', '2020-03-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (463, 'Serge', 463, '00463/2019-oct', '2019-10-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (464, 'Serge', 464, '00464/2019-aug', '2019-08-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (465, 'Serge', 465, '00465/2019-jul', '2019-07-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (466, 'Serge', 466, '00466/2020-apr', '2020-04-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (467, 'Serge', 467, '00467/2019-dec', '2019-12-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (468, 'Serge', 468, '00468/2019-sep', '2019-09-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (469, 'Serge', 469, '00469/2020-feb', '2020-02-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (470, 'Serge', 470, '00470/2019-aug', '2019-08-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (471, 'Serge', 471, '00471/2019-jun', '2019-06-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (472, 'Serge', 472, '00472/2020-feb', '2020-02-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (473, 'Serge', 473, '00473/2020-apr', '2020-04-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (474, 'Serge', 474, '00474/2019-jul', '2019-07-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (475, 'O''Henry', 475, '00475/2019-dec', '2019-12-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (476, 'O''Henry', 476, '00476/2020-feb', '2020-02-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (477, 'O''Henry', 477, '00477/2019-sep', '2019-09-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (478, 'O''Henry', 478, '00478/2019-dec', '2019-12-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (479, 'O''Henry', 479, '00479/2019-oct', '2019-10-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (480, 'O''Henry', 480, '00480/2019-jul', '2019-07-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (481, 'O''Henry', 481, '00481/2019-dec', '2019-12-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (482, 'O''Henry', 482, '00482/2019-nov', '2019-11-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (483, 'O''Henry', 483, '00483/2020-may', '2020-05-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (484, 'O''Henry', 484, '00484/2019-may', '2019-05-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (485, 'O''Henry', 485, '00485/2019-dec', '2019-12-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (486, 'O''Henry', 486, '00486/2020-feb', '2020-02-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (487, 'O''Henry', 487, '00487/2019-sep', '2019-09-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (488, 'O''Henry', 488, '00488/2019-sep', '2019-09-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (489, 'O''Henry', 489, '00489/2019-jul', '2019-07-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (490, 'O''Henry', 490, '00490/2020-jan', '2020-01-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (491, 'O''Henry', 491, '00491/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (492, 'O''Henry', 492, '00492/2019-jul', '2019-07-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (493, 'O''Henry', 493, '00493/2019-oct', '2019-10-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (494, 'O''Henry', 494, '00494/2019-oct', '2019-10-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (495, 'O''Henry', 495, '00495/2019-dec', '2019-12-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (496, 'O''Henry', 496, '00496/2020-mar', '2020-03-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (497, 'O''Henry', 497, '00497/2020-apr', '2020-04-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (498, 'O''Henry', 498, '00498/2019-nov', '2019-11-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (499, 'O''Henry', 499, '00499/2019-dec', '2019-12-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (500, 'O''Henry', 500, '00500/2019-dec', '2019-12-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (501, 'O''Henry', 501, '00501/2019-dec', '2019-12-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (502, 'O''Henry', 502, '00502/2020-feb', '2020-02-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (503, 'O''Henry', 503, '00503/2020-mar', '2020-03-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (504, 'O''Henry', 504, '00504/2019-may', '2019-05-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (505, 'O''Henry', 505, '00505/2019-may', '2019-05-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (506, 'O''Henry', 506, '00506/2020-jan', '2020-01-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (507, 'O''Henry', 507, '00507/2020-feb', '2020-02-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (508, 'O''Henry', 508, '00508/2020-jan', '2020-01-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (509, 'O''Henry', 509, '00509/2020-apr', '2020-04-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (510, 'O''Henry', 510, '00510/2019-jul', '2019-07-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (511, 'O''Henry', 511, '00511/2020-feb', '2020-02-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (512, 'O''Henry', 512, '00512/2019-jul', '2019-07-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (513, 'O''Henry', 513, '00513/2019-jun', '2019-06-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (514, 'O''Henry', 514, '00514/2019-sep', '2019-09-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (515, 'O''Henry', 515, '00515/2019-nov', '2019-11-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (516, 'O''Henry', 516, '00516/2020-jan', '2020-01-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (517, 'O''Henry', 517, '00517/2019-aug', '2019-08-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (518, 'O''Henry', 518, '00518/2019-sep', '2019-09-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (519, 'O''Henry', 519, '00519/2019-aug', '2019-08-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (520, 'O''Henry', 520, '00520/2019-oct', '2019-10-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (521, 'O''Henry', 521, '00521/2020-jan', '2020-01-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (522, 'O''Henry', 522, '00522/2019-jun', '2019-06-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (523, 'O''Henry', 523, '00523/2019-jun', '2019-06-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (524, 'O''Henry', 524, '00524/2019-sep', '2019-09-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (525, 'O''Henry', 525, '00525/2019-oct', '2019-10-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (526, 'O''Henry', 526, '00526/2020-apr', '2020-04-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (527, 'O''Henry', 527, '00527/2020-jan', '2020-01-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (528, 'O''Henry', 528, '00528/2019-oct', '2019-10-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (529, 'O''Henry', 529, '00529/2019-dec', '2019-12-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (530, 'O''Henry', 530, '00530/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (531, 'O''Henry', 531, '00531/2019-sep', '2019-09-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (532, 'O''Henry', 532, '00532/2019-jun', '2019-06-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (533, 'O''Henry', 533, '00533/2019-jun', '2019-06-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (534, 'O''Henry', 534, '00534/2019-jul', '2019-07-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (535, 'O''Henry', 535, '00535/2020-jan', '2020-01-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (536, 'O''Henry', 536, '00536/2020-feb', '2020-02-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (537, 'O''Henry', 537, '00537/2019-aug', '2019-08-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (538, 'O''Henry', 538, '00538/2019-may', '2019-05-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (539, 'O''Henry', 539, '00539/2019-jun', '2019-06-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (540, 'O''Henry', 540, '00540/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (541, 'O''Henry', 541, '00541/2020-mar', '2020-03-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (542, 'O''Henry', 542, '00542/2019-sep', '2019-09-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (543, 'O''Henry', 543, '00543/2020-feb', '2020-02-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (544, 'O''Henry', 544, '00544/2019-oct', '2019-10-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (545, 'O''Henry', 545, '00545/2019-dec', '2019-12-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (546, 'O''Henry', 546, '00546/2019-aug', '2019-08-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (547, 'O''Henry', 547, '00547/2019-aug', '2019-08-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (548, 'O''Henry', 548, '00548/2019-jun', '2019-06-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (549, 'O''Henry', 549, '00549/2019-dec', '2019-12-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (550, 'O''Henry', 550, '00550/2019-aug', '2019-08-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (551, 'O''Henry', 551, '00551/2019-sep', '2019-09-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (552, 'O''Henry', 552, '00552/2020-mar', '2020-03-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (553, 'O''Henry', 553, '00553/2020-feb', '2020-02-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (554, 'O''Henry', 554, '00554/2019-dec', '2019-12-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (555, 'O''Henry', 555, '00555/2020-apr', '2020-04-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (556, 'O''Henry', 556, '00556/2019-sep', '2019-09-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (557, 'O''Henry', 557, '00557/2020-mar', '2020-03-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (558, 'O''Henry', 558, '00558/2019-aug', '2019-08-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (559, 'O''Henry', 559, '00559/2019-sep', '2019-09-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (560, 'O''Henry', 560, '00560/2020-mar', '2020-03-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (561, 'Stasy', 561, '00561/2019-nov', '2019-11-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (562, 'Stasy', 562, '00562/2019-oct', '2019-10-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (564, 'Stasy', 564, '00564/2020-may', '2020-05-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (565, 'Stasy', 565, '00565/2019-jun', '2019-06-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (566, 'Stasy', 566, '00566/2019-dec', '2019-12-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (567, 'Stasy', 567, '00567/2020-jan', '2020-01-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (568, 'Stasy', 568, '00568/2019-may', '2019-05-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (569, 'Stasy', 569, '00569/2020-jan', '2020-01-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (570, 'Stasy', 570, '00570/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (571, 'Stasy', 571, '00571/2019-oct', '2019-10-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (572, 'Stasy', 572, '00572/2019-dec', '2019-12-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (573, 'Stasy', 573, '00573/2019-oct', '2019-10-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (574, 'Stasy', 574, '00574/2019-dec', '2019-12-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (575, 'Stasy', 575, '00575/2020-may', '2020-05-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (576, 'Stasy', 576, '00576/2019-jul', '2019-07-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (577, 'Stasy', 577, '00577/2020-mar', '2020-03-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (578, 'Stasy', 578, '00578/2019-may', '2019-05-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (579, 'Stasy', 579, '00579/2019-may', '2019-05-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (580, 'Stasy', 580, '00580/2019-dec', '2019-12-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (581, 'Stasy', 581, '00581/2019-jul', '2019-07-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (582, 'Stasy', 582, '00582/2019-aug', '2019-08-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (583, 'Stasy', 583, '00583/2020-jan', '2020-01-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (584, 'Stasy', 584, '00584/2019-jun', '2019-06-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (585, 'Stasy', 585, '00585/2020-jan', '2020-01-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (586, 'Stasy', 586, '00586/2019-nov', '2019-11-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (587, 'Stasy', 587, '00587/2019-dec', '2019-12-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (588, 'Stasy', 588, '00588/2019-oct', '2019-10-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (589, 'Stasy', 589, '00589/2019-oct', '2019-10-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (590, 'Т Ларина', 590, '00590/2019-jun', '2019-06-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (591, 'Т Ларина', 591, '00591/2019-jul', '2019-07-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (592, 'Т Ларина', 592, '00592/2019-oct', '2019-10-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (593, 'Т Ларина', 593, '00593/2019-may', '2019-05-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (594, 'Т Ларина', 594, '00594/2019-jul', '2019-07-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (595, 'Т Ларина', 595, '00595/2019-sep', '2019-09-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (596, 'Т Ларина', 596, '00596/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (597, 'Т Ларина', 597, '00597/2019-nov', '2019-11-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (598, 'Т Ларина', 598, '00598/2019-dec', '2019-12-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (599, 'Т Ларина', 599, '00599/2020-jan', '2020-01-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (600, 'Т Ларина', 600, '00600/2019-jul', '2019-07-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (601, 'Т Ларина', 601, '00601/2019-oct', '2019-10-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (602, 'Т Ларина', 602, '00602/2019-may', '2019-05-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (603, 'Т Ларина', 603, '00603/2019-jun', '2019-06-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (604, 'Т Ларина', 604, '00604/2020-apr', '2020-04-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (605, 'Т Ларина', 605, '00605/2019-oct', '2019-10-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (606, 'Т Ларина', 606, '00606/2020-jan', '2020-01-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (607, 'Т Ларина', 607, '00607/2020-mar', '2020-03-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (608, 'Т Ларина', 608, '00608/2019-aug', '2019-08-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (609, 'Т Ларина', 609, '00609/2019-jul', '2019-07-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (610, 'Т Ларина', 610, '00610/2019-nov', '2019-11-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (611, 'Т Ларина', 611, '00611/2020-jan', '2020-01-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (612, 'Т Ларина', 612, '00612/2020-mar', '2020-03-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (613, 'Т Ларина', 613, '00613/2019-dec', '2019-12-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (614, 'Т Ларина', 614, '00614/2019-oct', '2019-10-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (615, 'Т Ларина', 615, '00615/2019-sep', '2019-09-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (616, 'Т Ларина', 616, '00616/2019-dec', '2019-12-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (617, 'Т Ларина', 617, '00617/2019-may', '2019-05-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (618, 'Т Ларина', 618, '00618/2019-nov', '2019-11-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (619, 'Т Ларина', 619, '00619/2019-jul', '2019-07-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (620, 'Т Ларина', 620, '00620/2020-feb', '2020-02-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (621, 'Т Ларина', 621, '00621/2019-dec', '2019-12-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (622, 'Т Ларина', 622, '00622/2020-feb', '2020-02-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (623, 'Т Ларина', 623, '00623/2019-nov', '2019-11-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (624, 'Т Ларина', 624, '00624/2020-jan', '2020-01-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (625, 'Т Ларина', 625, '00625/2019-nov', '2019-11-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (626, 'Т Ларина', 626, '00626/2019-aug', '2019-08-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (627, 'Т Ларина', 627, '00627/2020-feb', '2020-02-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (628, 'Т Ларина', 628, '00628/2019-nov', '2019-11-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (629, 'Т Ларина', 629, '00629/2019-aug', '2019-08-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (630, 'Т Ларина', 630, '00630/2020-feb', '2020-02-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (631, 'Т Ларина', 631, '00631/2019-oct', '2019-10-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (632, 'Т Ларина', 632, '00632/2019-jun', '2019-06-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (633, 'Т Ларина', 633, '00633/2019-aug', '2019-08-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (634, 'Т Ларина', 634, '00634/2020-apr', '2020-04-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (635, 'Т Ларина', 635, '00635/2019-nov', '2019-11-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (636, 'Т Ларина', 636, '00636/2020-jan', '2020-01-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (637, 'Т Ларина', 637, '00637/2019-oct', '2019-10-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (638, 'Т Ларина', 638, '00638/2019-jul', '2019-07-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (639, 'Т Ларина', 639, '00639/2019-jul', '2019-07-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (640, 'Т Ларина', 640, '00640/2020-may', '2020-05-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (641, 'Т Ларина', 641, '00641/2019-dec', '2019-12-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (642, 'Т Ларина', 642, '00642/2019-nov', '2019-11-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (643, 'Т Ларина', 643, '00643/2019-dec', '2019-12-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (644, 'Т Ларина', 644, '00644/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (645, 'Т Ларина', 645, '00645/2019-jul', '2019-07-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (646, 'Т Ларина', 646, '00646/2019-nov', '2019-11-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (647, 'Т Ларина', 647, '00647/2020-jan', '2020-01-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (648, 'Т Ларина', 648, '00648/2019-jul', '2019-07-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (649, 'Т Ларина', 649, '00649/2020-mar', '2020-03-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (650, 'Т Ларина', 650, '00650/2019-oct', '2019-10-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (651, 'Т Ларина', 651, '00651/2020-apr', '2020-04-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (652, 'Т Ларина', 652, '00652/2019-dec', '2019-12-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (653, 'Т Ларина', 653, '00653/2020-apr', '2020-04-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (654, 'Т Ларина', 654, '00654/2020-apr', '2020-04-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (655, 'Т Ларина', 655, '00655/2019-may', '2019-05-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (656, 'Т Ларина', 656, '00656/2019-jun', '2019-06-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (657, 'Т Ларина', 657, '00657/2020-apr', '2020-04-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (658, 'Т Ларина', 658, '00658/2019-jun', '2019-06-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (659, 'Т Ларина', 659, '00659/2020-apr', '2020-04-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (660, 'Т Ларина', 660, '00660/2020-may', '2020-05-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (661, 'Т Ларина', 661, '00661/2019-oct', '2019-10-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (662, 'Т Ларина', 662, '00662/2019-aug', '2019-08-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (663, 'Т Ларина', 663, '00663/2019-jun', '2019-06-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (664, 'Т Ларина', 664, '00664/2019-jul', '2019-07-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (665, 'Т Ларина', 665, '00665/2020-mar', '2020-03-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (666, 'О Ларина', 666, '00666/2019-oct', '2019-10-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (667, 'О Ларина', 667, '00667/2019-may', '2019-05-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (668, 'О Ларина', 668, '00668/2019-oct', '2019-10-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (669, 'О Ларина', 669, '00669/2020-jan', '2020-01-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (670, 'О Ларина', 670, '00670/2020-may', '2020-05-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (671, 'О Ларина', 671, '00671/2019-jul', '2019-07-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (672, 'О Ларина', 672, '00672/2019-aug', '2019-08-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (673, 'О Ларина', 673, '00673/2019-aug', '2019-08-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (674, 'О Ларина', 674, '00674/2019-oct', '2019-10-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (675, 'О Ларина', 675, '00675/2019-jun', '2019-06-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (676, 'О Ларина', 676, '00676/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (677, 'О Ларина', 677, '00677/2020-feb', '2020-02-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (678, 'О Ларина', 678, '00678/2019-nov', '2019-11-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (679, 'О Ларина', 679, '00679/2020-apr', '2020-04-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (680, 'О Ларина', 680, '00680/2019-jun', '2019-06-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (681, 'О Ларина', 681, '00681/2019-aug', '2019-08-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (682, 'О Ларина', 682, '00682/2019-sep', '2019-09-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (683, 'О Ларина', 683, '00683/2020-apr', '2020-04-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (684, 'О Ларина', 684, '00684/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (685, 'О Ларина', 685, '00685/2020-jan', '2020-01-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (686, 'О Ларина', 686, '00686/2020-mar', '2020-03-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (687, 'О Ларина', 687, '00687/2020-feb', '2020-02-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (688, 'О Ларина', 688, '00688/2020-mar', '2020-03-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (689, 'О Ларина', 689, '00689/2019-dec', '2019-12-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (690, 'О Ларина', 690, '00690/2020-may', '2020-05-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (691, 'О Ларина', 691, '00691/2019-sep', '2019-09-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (692, 'О Ларина', 692, '00692/2020-feb', '2020-02-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (693, 'О Ларина', 693, '00693/2019-dec', '2019-12-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (694, 'О Ларина', 694, '00694/2019-oct', '2019-10-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (695, 'О Ларина', 695, '00695/2019-jul', '2019-07-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (696, 'О Ларина', 696, '00696/2020-apr', '2020-04-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (697, 'О Ларина', 697, '00697/2020-mar', '2020-03-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (698, 'О Ларина', 698, '00698/2020-jan', '2020-01-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (699, 'О Ларина', 699, '00699/2019-nov', '2019-11-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (700, 'О Ларина', 700, '00700/2019-nov', '2019-11-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (701, 'О Ларина', 701, '00701/2019-sep', '2019-09-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (702, 'О Ларина', 702, '00702/2019-jul', '2019-07-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (703, 'О Ларина', 703, '00703/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (704, 'О Ларина', 704, '00704/2019-nov', '2019-11-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (705, 'О Ларина', 705, '00705/2019-jun', '2019-06-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (706, 'О Ларина', 706, '00706/2019-sep', '2019-09-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (707, 'О Ларина', 707, '00707/2019-sep', '2019-09-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (708, 'О Ларина', 708, '00708/2019-sep', '2019-09-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (709, 'О Ларина', 709, '00709/2020-feb', '2020-02-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (710, 'О Ларина', 710, '00710/2019-jun', '2019-06-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (711, 'О Ларина', 711, '00711/2019-aug', '2019-08-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (712, 'О Ларина', 712, '00712/2019-oct', '2019-10-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (713, 'О Ларина', 713, '00713/2019-jul', '2019-07-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (714, 'О Ларина', 714, '00714/2019-may', '2019-05-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (715, 'О Ларина', 715, '00715/2020-mar', '2020-03-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (716, 'О Ларина', 716, '00716/2020-mar', '2020-03-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (717, 'О Ларина', 717, '00717/2019-oct', '2019-10-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (718, 'О Ларина', 718, '00718/2019-may', '2019-05-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (719, 'О Ларина', 719, '00719/2019-oct', '2019-10-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (720, 'О Ларина', 720, '00720/2019-sep', '2019-09-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (721, 'О Ларина', 721, '00721/2020-apr', '2020-04-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (722, 'О Ларина', 722, '00722/2019-aug', '2019-08-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (723, 'О Ларина', 723, '00723/2020-apr', '2020-04-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (724, 'О Ларина', 724, '00724/2019-oct', '2019-10-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (725, 'О Ларина', 725, '00725/2019-jun', '2019-06-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (726, 'О Ларина', 726, '00726/2019-dec', '2019-12-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (727, 'О Ларина', 727, '00727/2020-feb', '2020-02-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (728, 'О Ларина', 728, '00728/2020-mar', '2020-03-19');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (729, 'О Ларина', 729, '00729/2019-jul', '2019-07-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (730, 'О Ларина', 730, '00730/2020-may', '2020-05-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (731, 'О Ларина', 731, '00731/2020-jan', '2020-01-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (732, 'О Ларина', 732, '00732/2019-jun', '2019-06-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (733, 'О Ларина', 733, '00733/2019-sep', '2019-09-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (734, 'О Ларина', 734, '00734/2019-may', '2019-05-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (735, 'mpd', 735, '00735/2020-mar', '2020-03-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (736, 'mpd', 736, '00736/2019-aug', '2019-08-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (737, 'mpd', 737, '00737/2019-may', '2019-05-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (738, 'mpd', 738, '00738/2019-jun', '2019-06-11');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (739, 'mpd', 739, '00739/2019-jun', '2019-06-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (740, 'mpd', 740, '00740/2019-aug', '2019-08-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (741, 'mpd', 741, '00741/2019-jun', '2019-06-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (742, 'mpd', 742, '00742/2020-mar', '2020-03-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (743, 'mpd', 743, '00743/2019-dec', '2019-12-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (744, 'mpd', 744, '00744/2019-jun', '2019-06-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (745, 'mpd', 745, '00745/2020-mar', '2020-03-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (746, 'mpd', 746, '00746/2019-jun', '2019-06-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (747, 'mpd', 747, '00747/2019-jun', '2019-06-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (748, 'mpd', 748, '00748/2020-mar', '2020-03-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (749, 'mpd', 749, '00749/2020-mar', '2020-03-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (750, 'mpd', 750, '00750/2019-nov', '2019-11-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (751, 'mpd', 751, '00751/2019-sep', '2019-09-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (752, 'mpd', 752, '00752/2020-apr', '2020-04-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (754, 'mpd', 754, '00754/2019-jun', '2019-06-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (755, 'mpd', 755, '00755/2019-sep', '2019-09-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (756, 'mpd', 756, '00756/2019-sep', '2019-09-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (757, 'mpd', 757, '00757/2019-aug', '2019-08-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (758, 'mpd', 758, '00758/2019-jul', '2019-07-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (759, 'mpd', 759, '00759/2019-dec', '2019-12-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (760, 'mpd', 760, '00760/2019-nov', '2019-11-16');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (761, 'mpd', 761, '00761/2019-jun', '2019-06-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (763, 'mpd', 763, '00763/2019-aug', '2019-08-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (764, 'mpd', 764, '00764/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (765, 'mpd', 765, '00765/2019-jun', '2019-06-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (766, 'mpd', 766, '00766/2020-apr', '2020-04-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (767, 'mpd', 767, '00767/2020-may', '2020-05-06');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (768, 'mpd', 768, '00768/2020-feb', '2020-02-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (769, 'mpd', 769, '00769/2020-jan', '2020-01-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (771, 'mpd', 771, '00771/2019-nov', '2019-11-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (772, 'mpd', 772, '00772/2019-sep', '2019-09-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (773, 'mpd', 773, '00773/2019-oct', '2019-10-29');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (774, 'mpd', 774, '00774/2020-mar', '2020-03-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (775, 'mpd', 775, '00775/2020-apr', '2020-04-28');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (777, 'mpd', 777, '00777/2019-oct', '2019-10-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (778, 'mpd', 778, '00778/2019-oct', '2019-10-18');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (779, 'mpd', 779, '00779/2019-oct', '2019-10-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (780, 'mpd', 780, '00780/2020-apr', '2020-04-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (782, 'mpd', 782, '00782/2020-apr', '2020-04-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (784, 'mpd', 784, '00784/2020-mar', '2020-03-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (785, 'mpd', 785, '00785/2019-nov', '2019-11-24');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (786, 'mpd', 786, '00786/2019-oct', '2019-10-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (787, 'mpd', 787, '00787/2020-mar', '2020-03-27');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (789, 'mpd', 789, '00789/2020-jan', '2020-01-23');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (790, 'mpd', 790, '00790/2019-jul', '2019-07-05');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (791, 'mpd', 791, '00791/2019-nov', '2019-11-30');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (792, 'mpd', 792, '00792/2019-jun', '2019-06-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (793, 'mpd', 793, '00793/2019-jun', '2019-06-02');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (794, 'mpd', 794, '00794/2019-jul', '2019-07-13');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (795, 'mpd', 795, '00795/2020-apr', '2020-04-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (799, 'Joury', 799, '00799/2019-aug', '2019-08-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (802, 'Joury', 802, '00802/2019-oct', '2019-10-03');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (804, 'Joury', 804, '00804/2020-mar', '2020-03-17');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (823, 'Joury', 823, '00823/2019-aug', '2019-08-21');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (826, 'Joury', 826, '00826/2020-feb', '2020-02-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (830, 'Joury', 830, '00830/2019-sep', '2019-09-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (835, 'Joury', 835, '00835/2020-apr', '2020-04-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (840, 'Nowhere Man', 840, '00840/2019-aug', '2019-08-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (841, 'Nowhere Man', 841, '00841/2020-mar', '2020-03-07');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (842, 'Nowhere Man', 842, '00842/2020-mar', '2020-03-31');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (843, 'Nowhere Man', 843, '00843/2019-jun', '2019-06-08');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (844, 'Nowhere Man', 844, '00844/2020-mar', '2020-03-14');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (845, 'Nowhere Man', 845, '00845/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (846, 'Nowhere Man', 846, '00846/2020-jan', '2020-01-22');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (847, 'Nowhere Man', 847, '00847/2019-sep', '2019-09-12');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (848, 'Nowhere Man', 848, '00848/2019-may', '2019-05-25');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (849, 'Nowhere Man', 849, '00849/2019-sep', '2019-09-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (850, 'Nowhere Man', 850, '00850/2019-nov', '2019-11-01');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (853, 'Nowhere Man', 853, '00853/2019-may', '2019-05-20');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (854, 'Nowhere Man', 854, '00854/2020-apr', '2020-04-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (855, 'Nowhere Man', 855, '00855/2019-aug', '2019-08-26');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (856, 'Nowhere Man', 856, '00856/2019-oct', '2019-10-15');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (857, 'Nowhere Man', 857, '00857/2019-oct', '2019-10-04');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (858, 'Nowhere Man', 858, '00858/2019-nov', '2019-11-10');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (859, 'Nowhere Man', 859, '00859/2019-jul', '2019-07-09');
INSERT INTO shop.order_main (order_id, client_login, order_cnt, order_no, order_date) VALUES (861, 'Nowhere Man', 861, '00861/2020-jan', '2020-01-30');
--
SELECT setval	(
		'shop.order_main_order_id_seq'::regclass,
		(SELECT MAX(order_id) FROM shop.order_main),
		true
		);
--
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (2, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (3, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (3, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (4, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (4, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (5, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (6, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (7, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (9, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (9, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (9, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (10, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (10, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (11, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (13, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (13, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (14, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (15, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (16, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (17, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (19, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (20, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (20, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (22, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (22, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (23, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (23, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (24, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (24, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (25, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (25, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (26, 6, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (27, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (27, 8, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (28, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (30, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (30, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (31, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (32, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (33, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (34, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (35, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (36, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (37, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (37, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (40, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (41, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (42, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (44, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (45, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (46, 8, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (48, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (48, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (50, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (50, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (51, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (51, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (52, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (53, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (53, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (54, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (55, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (55, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (55, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (56, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (58, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (59, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (60, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (61, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (62, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (62, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (63, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (64, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (64, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (65, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (66, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (67, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (68, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (68, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (70, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (70, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (72, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (72, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (73, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (73, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (74, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (74, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (74, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (75, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (75, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (75, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (76, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (77, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (77, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (78, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (78, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (79, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (79, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (80, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (80, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (80, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (81, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (82, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (82, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (82, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (82, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (83, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (83, 1, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (84, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (84, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (85, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (85, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (85, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (86, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (86, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (87, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (87, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (88, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (88, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (88, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (89, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (89, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (89, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (90, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (90, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (91, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (91, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (91, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (92, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (92, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (92, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (93, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (93, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (94, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (94, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (94, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (95, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (95, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (95, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (96, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (96, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (97, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (97, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (98, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (99, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (100, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (100, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (101, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (101, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (102, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (102, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (103, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (103, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (103, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (104, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (104, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (104, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (104, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (105, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (105, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (106, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (106, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (107, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (107, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (107, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (108, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (108, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (109, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (109, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (110, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (110, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (110, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (111, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (111, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (112, 8, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (112, 6, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (113, 8, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (113, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (113, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (114, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (115, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (115, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (116, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (117, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (117, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (117, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (118, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (118, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (119, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (119, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (119, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (120, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (120, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (121, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (121, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (121, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (122, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (123, 8, 2, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (123, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (123, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (124, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (124, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (124, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (125, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (125, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (125, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (126, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (126, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (126, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (127, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (127, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (127, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (128, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (128, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (129, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (129, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (129, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (130, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (130, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (130, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (131, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (131, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (131, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (132, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (132, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (133, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (133, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (134, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (134, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (134, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (135, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (136, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (137, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (137, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (137, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (138, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (141, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (142, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (142, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (143, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (143, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (144, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (144, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (145, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (145, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (146, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (146, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (147, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (147, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (149, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (151, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (153, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (155, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (160, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (161, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (163, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (164, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (166, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (167, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (168, 4, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (169, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (169, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (170, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (172, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (175, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (177, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (178, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (181, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (182, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (182, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (182, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (182, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (183, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (183, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (183, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (184, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (184, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (185, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (185, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (185, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (186, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (187, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (188, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (189, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (189, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (189, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (190, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (190, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (191, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (191, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (192, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (192, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (192, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (193, 6, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (193, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (194, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (194, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (194, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (195, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (195, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (196, 5, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (196, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (197, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (197, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (198, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (198, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (199, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (199, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (199, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (200, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (201, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (201, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (201, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (202, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (202, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (203, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (204, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (204, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (205, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (205, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (206, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (206, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (207, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (207, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (207, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (208, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (209, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (209, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (210, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (210, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (210, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (210, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (211, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (211, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (212, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (212, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (213, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (213, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (214, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (214, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (215, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (215, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (215, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (215, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (216, 2, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (217, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (217, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (217, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (218, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (218, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (218, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (218, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (219, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (219, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (220, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (220, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (221, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (221, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (222, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (222, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (223, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (223, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (224, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (225, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (225, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (226, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (226, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (226, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (227, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (227, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (227, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (228, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (228, 9, 2, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (229, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (229, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (229, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (229, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (230, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (230, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (231, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (231, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (232, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (232, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (232, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (233, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (233, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (234, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (234, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (235, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (235, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (235, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (236, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (236, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (237, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (237, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (237, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (238, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (238, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (239, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (239, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (239, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (240, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (240, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (241, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (242, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (242, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (243, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (243, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (243, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (244, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (245, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (245, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (245, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (245, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (246, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (246, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (247, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (247, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (248, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (248, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (249, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (249, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (250, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (250, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (250, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (251, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (251, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (252, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (252, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (253, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (253, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (254, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (254, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (255, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (255, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (256, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (256, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (257, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (257, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (258, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (259, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (259, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (259, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (260, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (261, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (261, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (261, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (262, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (263, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (263, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (263, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (264, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (265, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (265, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (265, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (266, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (266, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (267, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (267, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (268, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (269, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (269, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (269, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (270, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (270, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (270, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (271, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (272, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (272, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (272, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (273, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (273, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (274, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (274, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (275, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (276, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (276, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (276, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (277, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (277, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (277, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (277, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (278, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (278, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (278, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (278, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (279, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (279, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (279, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (280, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (280, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (281, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (281, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (282, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (283, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (283, 5, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (284, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (284, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (285, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (286, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (286, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (287, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (288, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (288, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (289, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (289, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (289, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (290, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (290, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (290, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (290, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (291, 5, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (291, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (291, 9, 2, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (292, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (292, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (293, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (293, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (294, 5, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (295, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (295, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (295, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (296, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (296, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (296, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (297, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (297, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (298, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (298, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (298, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (299, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (300, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (300, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (301, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (301, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (302, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (303, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (303, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (303, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (303, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (304, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (304, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (304, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (305, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (305, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (305, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (306, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (306, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (307, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (307, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (307, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (308, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (308, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (308, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (309, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (309, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (309, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (309, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (310, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (310, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (310, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (311, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (311, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (312, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (314, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (315, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (316, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (318, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (322, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (323, 7, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (324, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (324, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (325, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (326, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (327, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (330, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (334, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (336, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (339, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (342, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (343, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (344, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (348, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (349, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (350, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (351, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (352, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (352, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (353, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (355, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (356, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (357, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (358, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (358, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (360, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (360, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (361, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (363, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (364, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (368, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (368, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (370, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (372, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (372, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (374, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (375, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (375, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (376, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (379, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (381, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (382, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (384, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (384, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (385, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (388, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (388, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (389, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (389, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (390, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (391, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (392, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (393, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (394, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (395, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (395, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (395, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (396, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (396, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (396, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (396, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (397, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (397, 7, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (398, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (398, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (398, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (399, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (399, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (399, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (400, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (400, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (401, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (401, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (401, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (402, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (402, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (402, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (403, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (403, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (404, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (404, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (404, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (405, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (405, 4, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (406, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (407, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (408, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (408, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (408, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (409, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (410, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (410, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (411, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (412, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (412, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (413, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (413, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (413, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (414, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (415, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (416, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (416, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (416, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (417, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (417, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (418, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (418, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (419, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (419, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (419, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (420, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (420, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (420, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (421, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (421, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (422, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (422, 9, 2, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (423, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (423, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (423, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (424, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (424, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (425, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (426, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (426, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (426, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (427, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (427, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (428, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (428, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (429, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (429, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (429, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (429, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (430, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (430, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (431, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (431, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (431, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (431, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (432, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (432, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (432, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (433, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (433, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (433, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (434, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (434, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (434, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (434, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (435, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (436, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (436, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (437, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (437, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (437, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (438, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (438, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (439, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (439, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (439, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (440, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (441, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (441, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (442, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (442, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (443, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (443, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (443, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (444, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (444, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (445, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (446, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (446, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (446, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (447, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (447, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (447, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (448, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (448, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (449, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (449, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (449, 7, 3, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (450, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (450, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (450, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (450, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (451, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (451, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (451, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (452, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (452, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (453, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (453, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (454, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (455, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (455, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (455, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (456, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (457, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (457, 3, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (457, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (458, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (458, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (459, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (460, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (460, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (460, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (461, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (461, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (462, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (462, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (462, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (463, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (464, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (465, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (465, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (465, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (466, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (466, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (466, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (467, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (467, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (468, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (469, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (469, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (470, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (470, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (471, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (471, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (472, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (473, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (473, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (474, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (474, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (475, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (475, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (476, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (476, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (477, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (477, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (478, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (478, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (479, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (479, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (480, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (481, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (481, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (481, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (482, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (482, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (483, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (483, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (483, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (484, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (484, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (484, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (484, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (485, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (485, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (485, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (486, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (486, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (487, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (488, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (488, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (488, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (489, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (490, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (490, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (491, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (491, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (491, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (492, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (492, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (493, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (493, 6, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (494, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (494, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (495, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (496, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (496, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (497, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (497, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (498, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (498, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (499, 6, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (499, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (500, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (501, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (501, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (501, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (502, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (502, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (503, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (504, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (505, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (506, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (506, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (506, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (507, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (507, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (508, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (509, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (510, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (510, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (510, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (511, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (511, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (512, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (512, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (513, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (513, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (514, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (514, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (514, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (515, 9, 1, 3);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (515, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (516, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (516, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (516, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (517, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (517, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (518, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (518, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (519, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (519, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (519, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (520, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (520, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (520, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (521, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (522, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (522, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (523, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (523, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (524, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (524, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (524, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (525, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (526, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (526, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (527, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (527, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (527, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (528, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (528, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (528, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (528, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (529, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (529, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (530, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (530, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (530, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (531, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (531, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (532, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (533, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (534, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (534, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (535, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (535, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (536, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (536, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (537, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (537, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (537, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (537, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (538, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (538, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (539, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (539, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (540, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (540, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (540, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (541, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (541, 5, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (542, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (542, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (542, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (543, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (544, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (544, 5, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (545, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (545, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (546, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (547, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (548, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (548, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (549, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (549, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (550, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (550, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (550, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (551, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (551, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (552, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (552, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (552, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (553, 7, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (553, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (554, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (555, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (556, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (556, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (556, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (556, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (557, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (557, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (558, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (559, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (560, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (560, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (560, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (561, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (562, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (562, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (564, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (565, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (565, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (566, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (567, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (567, 8, 3, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (567, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (568, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (568, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (568, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (569, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (570, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (571, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (572, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (573, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (574, 7, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (574, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (575, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (575, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (576, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (576, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (577, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (578, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (579, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (579, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (580, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (580, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (581, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (582, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (582, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (582, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (583, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (584, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (585, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (586, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (587, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (587, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (587, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (588, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (589, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (590, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (591, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (592, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (592, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (593, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (593, 5, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (593, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (594, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (594, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (595, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (596, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (596, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (596, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (596, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (597, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (597, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (597, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (598, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (599, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (599, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (599, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (600, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (600, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (601, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (602, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (602, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (603, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (604, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (604, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (604, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (605, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (605, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (606, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (606, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (606, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (606, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (607, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (607, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (607, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (608, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (608, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (609, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (609, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (609, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (609, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (610, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (610, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (610, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (611, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (611, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (612, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (613, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (614, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (614, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (614, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (615, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (615, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (615, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (616, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (616, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (616, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (616, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (617, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (617, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (617, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (617, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (618, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (618, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (618, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (618, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (619, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (619, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (619, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (620, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (620, 5, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (621, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (621, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (622, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (622, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (623, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (623, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (624, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (624, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (624, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (624, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (625, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (625, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (625, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (626, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (626, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (626, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (627, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (627, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (628, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (628, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (629, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (629, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (630, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (631, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (631, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (631, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (631, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (632, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (632, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (633, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (633, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (634, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (635, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (635, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (636, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (636, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (637, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (637, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (638, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (638, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (639, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (639, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (639, 6, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (640, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (641, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (641, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (641, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (642, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (642, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (642, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (643, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (643, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (643, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (644, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (645, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (646, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (646, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (647, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (647, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (647, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (648, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (648, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (649, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (649, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (650, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (650, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (651, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (652, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (652, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (653, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (653, 2, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (654, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (655, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (655, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (655, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (656, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (656, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (656, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (657, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (657, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (657, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (658, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (658, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (658, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (659, 9, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (659, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (659, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (660, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (660, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (660, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (661, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (662, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (662, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (662, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (662, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (663, 5, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (663, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (664, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (664, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (664, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (665, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (666, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (667, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (667, 2, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (668, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (669, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (669, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (669, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (670, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (670, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (671, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (672, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (672, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (673, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (674, 1, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (674, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (674, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (674, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (675, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (675, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (675, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (675, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (676, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (676, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (677, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (678, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (678, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (678, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (679, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (680, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (680, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (681, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (682, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (682, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (683, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (683, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (684, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (685, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (686, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (686, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (687, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (687, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (688, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (688, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (688, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (689, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (689, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (689, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (690, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (690, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (690, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (691, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (691, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (692, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (693, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (693, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (694, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (694, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (695, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (695, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (695, 6, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (696, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (696, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (697, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (697, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (698, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (698, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (698, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (699, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (699, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (700, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (700, 8, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (700, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (701, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (701, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (702, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (702, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (703, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (703, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (703, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (703, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (704, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (705, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (706, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (707, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (707, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (708, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (708, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (709, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (709, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (710, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (710, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (710, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (710, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (711, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (711, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (711, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (712, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (712, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (713, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (714, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (714, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (715, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (715, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (715, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (716, 9, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (716, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (717, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (717, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (717, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (717, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (718, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (718, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (718, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (719, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (719, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (720, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (721, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (721, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (722, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (722, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (722, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (722, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (723, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (724, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (724, 9, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (725, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (725, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (725, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (726, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (726, 7, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (726, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (727, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (728, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (728, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (729, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (729, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (730, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (730, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (730, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (731, 7, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (731, 2, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (732, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (732, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (733, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (733, 7, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (734, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (734, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (734, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (735, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (735, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (735, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (736, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (736, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (736, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (737, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (737, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (738, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (738, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (739, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (739, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (740, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (741, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (741, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (742, 8, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (743, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (744, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (744, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (745, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (745, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (746, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (746, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (747, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (748, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (749, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (749, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (749, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (750, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (751, 3, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (752, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (752, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (752, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (754, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (755, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (755, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (756, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (756, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (757, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (757, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (758, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (759, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (759, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (759, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (760, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (760, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (760, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (761, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (761, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (761, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (763, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (764, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (764, 3, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (765, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (766, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (766, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (767, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (768, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (769, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (769, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (771, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (771, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (772, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (772, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (773, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (774, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (774, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (774, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (775, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (775, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (777, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (777, 6, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (778, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (778, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (779, 8, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (779, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (780, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (780, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (782, 3, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (784, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (784, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (785, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (785, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (785, 1, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (786, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (786, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (787, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (787, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (789, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (789, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (790, 8, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (790, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (791, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (791, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (791, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (792, 6, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (793, 6, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (793, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (794, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (794, 8, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (795, 2, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (799, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (802, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (804, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (823, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (826, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (830, 1, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (835, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (840, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (841, 4, 2, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (842, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (843, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (843, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (844, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (845, 5, 3, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (846, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (846, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (847, 4, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (848, 3, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (849, 2, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (850, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (853, 5, 2, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (854, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (854, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (854, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (855, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (856, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (856, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (857, 3, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (857, 1, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (857, 4, 1, 2);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (858, 5, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (858, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (859, 2, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (861, 4, 1, 1);
INSERT INTO shop.order_detail (order_id, book_id, qty, price_category_no) VALUES (861, 1, 1, 1);
------------------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS book_store.warehouse;
CREATE TABLE book_store.warehouse
(
	warehouse_id	serial PRIMARY KEY,
	warehouse_name	varchar(255) NOT NULL
);
ALTER TABLE book_store.warehouse OWNER TO student;


COMMENT ON TABLE book_store.warehouse
IS 'Склады

Дата создания:	03.05.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.warehouse.warehouse_id	IS 'Идентификатор склада';
COMMENT ON COLUMN book_store.warehouse.warehouse_name	IS 'Наименование склада';
-----------------------------------------------------------------------------------------------------------------------------


-- DROP TABLE IF EXISTS book_store.storage
CREATE TABLE book_store.storage
(
	storage_id		serial PRIMARY KEY,
	book_id			integer NOT NULL REFERENCES book_store.book (book_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT DEFERRABLE,
	warehouse_id	integer NOT NULL REFERENCES book_store.warehouse (warehouse_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT DEFERRABLE,
	rack_no			smallint NOT NULL,
	row_no			smallint NOT NULL,
	posit_no		smallint NOT NULL,
	qty				smallint NOT NULL CHECK (qty > 0),

	CONSTRAINT uq_storage UNIQUE (warehouse_id, row_no, rack_no, posit_no)	-- не храним разные книги в одном месте на одной полке!
);
ALTER TABLE book_store.storage OWNER TO student;


COMMENT ON TABLE book_store.storage
IS 'Информация о месте хранения

	!!! 	в текущей реализации поле storage_id скорее всего избыточно (можно сделать композитный PK вместо uq_storage), т.к. 
		не планируем ссылаться на эту таблицу. Но в дальнейшем такие ссылки могут потребоваться

Дата создания:	03.05.2020 (Admin)
Дата изменения:	
';

COMMENT ON COLUMN book_store.storage.storage_id		IS 'Идентификатор записи';
COMMENT ON COLUMN book_store.storage.book_id		IS 'Книга';
COMMENT ON COLUMN book_store.storage.warehouse_id	IS 'Склад';
COMMENT ON COLUMN book_store.storage.rack_no		IS '№ стеллажа';
COMMENT ON COLUMN book_store.storage.row_no			IS '№ ряда (полки)';
COMMENT ON COLUMN book_store.storage.posit_no		IS '№ места ';
COMMENT ON COLUMN book_store.storage.qty			IS 'количество';
-----------------------------------------------------------------------------------------------------------------------------


INSERT INTO book_store.warehouse (warehouse_id, warehouse_name) VALUES (1, 'Где-то в тамбовской области');	--

SELECT setval	(
		'book_store.warehouse_warehouse_id_seq'::regclass,
		(SELECT MAX(warehouse_id) FROM book_store.warehouse	),
		true
		);	
-----------------------------------------------------------------------------------------------------------------------------
		
INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (1, 1, 1, 7, 2, 3, 20);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (2, 1, 1, 8, 1, 2, 16);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (4, 1, 1, 8, 1, 3, 40);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (5, 1, 1, 3, 3, 4, 27);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (6, 2, 1, 8, 3, 3, 15);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (7, 2, 1, 4, 2, 2, 22);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (8, 2, 1, 5, 3, 2, 33);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (9, 4, 1, 7, 1, 3, 17);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (10, 4, 1, 5, 1, 2, 3);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (11, 5, 1, 3, 2, 2, 40);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (12, 5, 1, 4, 4, 4, 23);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (13, 5, 1, 1, 1, 3, 31);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (14, 6, 1, 8, 4, 1, 24);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (15, 7, 1, 6, 2, 5, 21);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (16, 8, 1, 6, 2, 6, 33);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (17, 8, 1, 7, 2, 4, 29);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (18, 8, 1, 4, 3, 5, 7);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (19, 8, 1, 8, 1, 5, 24);

INSERT INTO book_store.storage (storage_id, book_id, warehouse_id, rack_no, row_no, posit_no, qty)
VALUES (20, 8, 1, 3, 4, 4, 6);

SELECT setval	(
		'book_store.storage_storage_id_seq'::regclass,
		(SELECT MAX(storage_id) FROM book_store.storage	),
		true
		);	
		
------------------------------------------------------------------------------------------------
COMMIT;



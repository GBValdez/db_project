CREATE USER C##project IDENTIFIED BY Contrasena;
ALTER USER C##LAB1 QUOTA UNLIMITED ON USERS;
GRANT DBA TO "C##PROJECT";

CREATE OR REPLACE PROCEDURE addBinnacleData(tableName IN VARCHAR2) AS
    queryData VARCHAR2(1000);
BEGIN
	queryData := 'ALTER TABLE ' || tableName || 
                ' ADD ( create_at DATE,'||
				' create_user_id INT, ' ||
                ' update_at DATE, ' ||
                ' update_user_id INT, ' ||
                ' delete_at DATE)';
	DBMS_OUTPUT.PUT_LINE('Columnas agregadas a la tabla ' || tableName);
                
    EXECUTE IMMEDIATE queryData;
	
    queryData := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_create_id FOREIGN KEY (CREATE_USER_ID) REFERENCES USERS(id)';

	EXECUTE IMMEDIATE queryData;

	queryData := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_update_id FOREIGN KEY (UPDATE_USER_ID) REFERENCES USERS(id)';

    EXECUTE IMMEDIATE queryData;
    -- Mensaje opcional de éxito
    DBMS_OUTPUT.PUT_LINE('Columna userId y clave foránea agregadas a la tabla ' || tableName);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de errores
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;



CREATE TABLE  rol(
	id int PRIMARY KEY,
	name varchar(50) NOT NULL
);


CREATE TABLE users(
	id int PRIMARY KEY,
	username varchar(50) NOT NULL,
	password varchar(255) NOT NULL,
	email varchar(50) NOT NULL,
	email_confirmed NUMBER(1),
	rol_id int NOT NULL,
	CONSTRAINT users_rol_id FOREIGN KEY (rol_id) REFERENCES rol(id)	
);

CREATE TABLE blood_Type(
	id int PRIMARY KEY ,
	name varchar2(5) NOT NULL ,
	description varchar2(100)
);

CREATE TABLE specialty(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT NULL
);

CREATE TABLE presc_status(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
);


CREATE TABLE dis_class(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
);

CREATE TABLE med_brand(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
);

CREATE TABLE pharma_form(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL,
	description varchar2(100) NOT null
);

CREATE TABLE dose_unit
(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
);

CREATE TABLE sex
(
	id int PRIMARY KEY ,
	name varchar2(10) NOT NULL 
);


CREATE TABLE doctor(
	cui varchar2(13) PRIMARY KEY,
	name varchar2(100) NOT null,
	birthday DATE NOT null,
	sex_id int NOT NULL,
	speciality_Id int NOT NULL,
	constraint doctor_sex_id foreign key (sex_id) references sex (id),
	constraint doctor_speciality_id foreign key (speciality_id) references specialty(id)
);

CREATE TABLE patient(
	cui varchar2(13) PRIMARY KEY,
	name varchar2(100) NOT null,
	birthday DATE NOT null,
	sex_id int NOT NULL,
	blood_Type_id int NOT NULL,
	constraint patient_sex_id foreign key (sex_id) references sex (id),
	constraint patient_speciality_id foreign key (speciality_id) references specialty(id)
);

BEGIN 
	addBinnacleData('users');
	addBinnacleData('rol');
END;

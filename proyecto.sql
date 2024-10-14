CREATE USER C##project IDENTIFIED BY Contrasena;
ALTER USER C##LAB1 QUOTA UNLIMITED ON USERS;
GRANT DBA TO "C##PROJECT";

CREATE OR REPLACE PROCEDURE pro_config_table (table_name IN varchar2)
AS 
BEGIN 
	pro_add_binnacle_data(table_name);
	pro_create_increment(table_name);
	pro_create_trigger_autoincrement(table_name);
END;


CREATE OR REPLACE PROCEDURE pro_create_increment(table_name IN varchar2) AS
query_data varchar(1000);
BEGIN
	query_data := 'CREATE SEQUENCE SEQ_' || table_name || ' START WITH 1 INCREMENT BY 1';
	EXECUTE IMMEDIATE query_data;
   DBMS_OUTPUT.PUT_LINE('Secuencia creada para la tabla ' || table_name);
  EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear la secuencia para la tabla ' || table_name || ': ' || SQLERRM);
END;

CREATE OR REPLACE PROCEDURE pro_create_trigger_autoincrement(table_name IN VARCHAR2) AS
    query_data VARCHAR2(1000);
BEGIN
    -- Crear el trigger para la tabla especificada
    query_data := 'CREATE OR REPLACE TRIGGER TRG_' || table_name || '_BI ' ||
                  'BEFORE INSERT ON ' || table_name || ' ' ||
                  'FOR EACH ROW ' ||
                  'BEGIN ' ||
                  '   IF :NEW.id IS NULL THEN ' ||  -- Solo autoincrementa si el id no es proporcionado
                  '       SELECT SEQ_' || table_name || '.NEXTVAL INTO :NEW.id FROM dual; ' ||
                  '   END IF; ' ||
                  'END;';

    EXECUTE IMMEDIATE query_data;
    DBMS_OUTPUT.PUT_LINE('Trigger autoincrementable creado para la tabla ' || table_name);
   EXCEPTION
    -- Manejo de errores
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear el trigger para la tabla ' || table_name || ': ' || SQLERRM);
END;

CREATE OR REPLACE PROCEDURE pro_add_binnacle_data(tableName IN VARCHAR2) AS
    query_data VARCHAR2(1000);
BEGIN
	query_data := 'ALTER TABLE ' || tableName || 
                ' ADD ( create_at DATE,'||
				' create_user_id INT, ' ||
                ' update_at DATE, ' ||
                ' update_user_id INT, ' ||
                ' delete_at DATE)';
	DBMS_OUTPUT.PUT_LINE('Columnas agregadas a la tabla ' || tableName);
                
    EXECUTE IMMEDIATE query_data;
	
    query_data := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_create_id FOREIGN KEY (CREATE_USER_ID) REFERENCES USERS(id)';

	EXECUTE IMMEDIATE query_data;

	query_data := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_update_id FOREIGN KEY (UPDATE_USER_ID) REFERENCES USERS(id)';

    EXECUTE IMMEDIATE query_data;
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

CREATE TABLE blood_type(
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
	constraint patient_blood_Type_id foreign key (blood_Type_id) references blood_type(id)
);

CREATE TABLE consultation(
	id int PRIMARY KEY,
	date_visit DATE NOT NULL,
	general_comments varchar2(100),
	doctor_cui varchar2(13) NOT null,
	patient_cui varchar2(13) NOT NULL,
	presc_status_id int NOT NULL,
	CONSTRAINT colsutation_doctor_id FOREIGN KEY (doctor_cui) REFERENCES doctor(cui),
	CONSTRAINT colsutation_patient_id FOREIGN KEY (patient_cui) REFERENCES patient(cui),
	CONSTRAINT colsutation_presc_status_id FOREIGN KEY (presc_status_id) REFERENCES presc_status(id)
);

CREATE TABLE diseases(
	id int PRIMARY KEY,
	name varchar2(30) NOT NULL,
	description varchar2(200) NOT NULL,
	sintomas varchar2(300) NOT NULL,
	classification_id int NOT NULL,
	CONSTRAINT disease_dis_class_id FOREIGN KEY (classification_id) REFERENCES dis_class(id)
);

CREATE TABLE pharma_form_dose_unit(
	id int PRIMARY KEY,
	pharma_form_id int NOT NULL,
	dose_unit_id int NOT NULL,
	CONSTRAINT pfdu_pharma_form_id FOREIGN KEY (pharma_form_id) REFERENCES pharma_form(id), 
	CONSTRAINT pfdu_dose_unit_id FOREIGN KEY (dose_unit_id) REFERENCES dose_unit(id)
);

CREATE TABLE medicine(
	id int PRIMARY KEY,
	name varchar2(30) NOT NULL,
	brand_id int NOT NULL,
	description varchar2(200) NOT NULL,
	composition varchar2(200) NOT NULL,
	pfdu_id int NOT NULL,
	recommended_amount float NOT NULL,
	indications varchar2(200) NOT NULL,
	adverse_effects varchar2(200) NOT NULL,
	CONSTRAINT medicine_brand_id FOREIGN KEY (brand_id) REFERENCES med_brand(id),
	CONSTRAINT medicine_pfdu_id FOREIGN KEY (pfdu_id) REFERENCES pharma_form_dose_unit(id) 
);

CREATE TABLE diseases_medicine (
	disease_id int NOT NULL,
	medicine_id int NOT NULL,
	recommended_dosage float NOT null,
	CONSTRAINT dm_disease_id FOREIGN KEY (disease_id) REFERENCES diseases(id),
	CONSTRAINT dm_medicine_id FOREIGN KEY (medicine_id) REFERENCES medicine(id)
);

CREATE TABLE diagnosed_disease(
	id int PRIMARY KEY,
	consultation_id int NOT NULL,
	disease_id int NOT NULL,
	CONSTRAINT dd_consultation_id FOREIGN KEY (consultation_id) REFERENCES consultation(id),
	CONSTRAINT dd_disease_id FOREIGN KEY (disease_id) REFERENCES diseases(id)
);

CREATE TABLE recommended_medication(
	id int PRIMARY KEY,
	diagnosed_disease_id int NOT NULL,
	dose float NOT NULL,
	frequency_hrs float NOT NULL,
	duration_days float,
	additional_instructions varchar2(200),
	medicine_id int NOT NULL,
	CONSTRAINT rec_med_diagnosed_disease_id FOREIGN KEY (diagnosed_disease_id) REFERENCES diagnosed_disease(id),
	CONSTRAINT rec_med_medicine_id FOREIGN KEY (medicine_id) REFERENCES medicine(id)
);

CREATE TABLE binnacle_header(
	id int PRIMARY KEY,
	table_name varchar(20) NOT NULL,
	operation char(1) NOT NULL,
	day_operation DATE NOT null,
	register_id int NOT null,
	user_id int NOT null,
	ip varchar(30) NOT null,
	CONSTRAINT b_header_user_id FOREIGN KEY (user_id) REFERENCES users(id) 
);

CREATE TABLE binnacle_body(
	id int PRIMARY KEY,
	field varchar(20) NOT null,
	previous_value varchar(255),
	new_value varchar(255) NOT null,
	binnacle_header_id int NOT NULL,
	CONSTRAINT binn_body_binn_header_id FOREIGN KEY (binnacle_header_id) REFERENCES binnacle_header(id)
);

BEGIN
	pro_config_table('users');
END;

BEGIN
    pro_config_table('users');
    pro_config_table('rol');
    pro_config_table('blood_type');
    pro_config_table('specialty');
    pro_add_binnacle_data('presc_status');
    pro_add_binnacle_data('dis_class');
    pro_add_binnacle_data('med_brand');
    pro_add_binnacle_data('pharma_form');
    pro_add_binnacle_data('dose_unit');
    pro_add_binnacle_data('sex');
    pro_add_binnacle_data('doctor');
    pro_add_binnacle_data('patient');
    pro_add_binnacle_data('consultation');
    pro_add_binnacle_data('diseases');
    pro_add_binnacle_data('pharma_form_dose_unit');
    pro_add_binnacle_data('medicine');
    pro_add_binnacle_data('diseases_medicine');
    pro_add_binnacle_data('diagnosed_disease');
    pro_add_binnacle_data('recommended_medication');    
END;
/

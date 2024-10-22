CREATE USER C##project IDENTIFIED BY Contrasena;
ALTER USER C##LAB1 QUOTA UNLIMITED ON USERS;
GRANT DBA TO "C##PROJECT";


CREATE OR REPLACE PROCEDURE pro_create_trigger_binnacle(
    table_name_find IN VARCHAR2,
    fieldID IN VARCHAR2  
) 
AUTHID CURRENT_USER
AS
    query_data VARCHAR2(32767); 
    v_field_value VARCHAR2(1000); 
    v_field_name VARCHAR2(100);
    i PLS_INTEGER := 1;
BEGIN
    query_data := 'CREATE OR REPLACE TRIGGER TRG_' || table_name_find || '_BINNACLE ' ||
                  'AFTER UPDATE ON ' || table_name_find || ' ' ||
                  'FOR EACH ROW ' ||
                  'DECLARE ' ||
                  'id_register INT; ' ||
                  'BEGIN ' ||
                  'SELECT SEQ_binnacle_header.NEXTVAL INTO id_register FROM dual; ' ||
                  'INSERT INTO BINNACLE_HEADER (ID, TABLE_NAME, OPERATION, REGISTER_ID, USER_ID, IP) ' ||
                  'VALUES (id_register, ''' || table_name_find || ''', ''U'', ';

    v_field_value := '';
    i := 1;

    LOOP
        v_field_name := REGEXP_SUBSTR(fieldID, '[^,]+', 1, i);
        
        EXIT WHEN v_field_name IS NULL;
        
        IF i > 1 THEN
            v_field_value := v_field_value || ' || '','' || '; 
        END IF;
        v_field_value := v_field_value || ':NEW.' || v_field_name;

        i := i + 1; 
    END LOOP;

    query_data := query_data || v_field_value || ', :NEW.UPDATE_USER_ID, :NEW.IP_UPDATE); ';
    
    FOR colum_name IN (SELECT column_name 
                       FROM all_tab_columns 
                       WHERE table_name = UPPER(table_name_find) 
                         AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
                         AND column_name NOT IN ('ID', fieldID, 'UPDATE_USER_ID', 'IP_UPDATE','CREATE_AT','CREATE_USER_ID'))
    LOOP  
        query_data := query_data || ' ' ||
                'IF :OLD.' || colum_name.column_name || ' != :NEW.' || colum_name.column_name || ' THEN ' ||
                'INSERT INTO BINNACLE_BODY (FIELD, PREVIOUS_VALUE, NEW_VALUE, BINNACLE_HEADER_ID) ' ||
                'VALUES (''' || colum_name.column_name || ''', :OLD.' || colum_name.column_name || ', :NEW.' || colum_name.column_name || ', id_register); ' ||
                'END IF; ';             
    END LOOP;
    
    query_data := query_data || 'END;';

    EXECUTE IMMEDIATE query_data;
    DBMS_OUTPUT.PUT_LINE('Trigger bitacora creado para la tabla ' || table_name_find);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear el trigger bitacora: ' || SQLERRM);
END;





SELECT column_name 
                       FROM all_tab_columns 
                       WHERE table_name = UPPER('doctor') 
                         AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
                         AND column_name NOT IN ('ID', 'CUI', 'UPDATE_USER_ID', 'IP_UPDATE');
--------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pro_config_table (table_name IN varchar2)
AUTHID CURRENT_USER
AS 
BEGIN 
	pro_add_binnacle_data(table_name);
	pro_create_increment(table_name);
	pro_create_trigger_autoincrement(table_name);
END;
-----------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pro_create_increment(table_name IN varchar2) 
AUTHID CURRENT_USER
AS
query_data varchar(1000);
BEGIN
	query_data := 'CREATE SEQUENCE SEQ_' || table_name || ' START WITH 1 INCREMENT BY 1';
	DBMS_OUTPUT.PUT_LINE(query_data);
   EXECUTE IMMEDIATE query_data;
   DBMS_OUTPUT.PUT_LINE('Secuencia creada para la tabla ' || table_name);
  EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear la secuencia para la tabla ' || table_name || ': ' || SQLERRM);
END;
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pro_create_trigger_autoincrement(table_name IN VARCHAR2) 
AUTHID CURRENT_USER
AS
    query_data VARCHAR2(1000);
BEGIN
    query_data := 'CREATE OR REPLACE TRIGGER TRG_' || table_name || '_BI ' ||
                  'BEFORE INSERT ON ' || table_name || ' ' ||
                  'FOR EACH ROW ' ||
                  'BEGIN ' ||
                  '   IF :NEW.id IS NULL THEN ' ||  
                  '       SELECT SEQ_' || table_name || '.NEXTVAL INTO :NEW.id FROM dual; ' ||
                  '   END IF; ' ||
                  'END;';

    EXECUTE IMMEDIATE query_data;
    DBMS_OUTPUT.PUT_LINE('Trigger autoincrementable creado para la tabla ' || table_name);
   EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear el trigger para la tabla ' || table_name || ': ' || SQLERRM);
END;
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pro_add_binnacle_data(tableName IN VARCHAR2) AS
    query_data VARCHAR2(1000);
BEGIN
	query_data := 'ALTER TABLE ' || tableName || 
                ' ADD ( create_at DATE default CURRENT_DATE,'||
				' create_user_id INT, ' ||
                ' update_at DATE, ' ||
                ' update_user_id INT, ' ||
                ' delete_at DATE, ' ||
                ' ip_update varchar2(20))';
	DBMS_OUTPUT.PUT_LINE('Columnas agregadas a la tabla ' || tableName);
                
    EXECUTE IMMEDIATE query_data;
	
    query_data := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_create_id FOREIGN KEY (CREATE_USER_ID) REFERENCES USERS(id)';

	EXECUTE IMMEDIATE query_data;

	query_data := 'ALTER TABLE ' || tableName || 
                ' ADD  CONSTRAINT ' || tableName || '_user_update_id FOREIGN KEY (UPDATE_USER_ID) REFERENCES USERS(id)';

    EXECUTE IMMEDIATE query_data;
    DBMS_OUTPUT.PUT_LINE('Columna userId y clave foránea agregadas a la tabla ' || tableName);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

----------------------------------------------------------------------------------------------------
CREATE TABLESPACE data_tablespace 
DATAFILE '/opt/oracle/oradata/projectDb/data_tablespace.dbf' 
SIZE 100M 
AUTOEXTEND ON 
NEXT 50M 
MAXSIZE UNLIMITED 
EXTENT MANAGEMENT LOCAL;

CREATE TABLESPACE index_tablespace 
DATAFILE '/opt/oracle/oradata/projectDb/index_tablespace.dbf' 
SIZE 100M 
AUTOEXTEND ON 
NEXT 50M 
MAXSIZE UNLIMITED 
EXTENT MANAGEMENT LOCAL;

CREATE TABLESPACE binnacle_tablespace 
DATAFILE '/opt/oracle/oradata/projectDb/binnacle_tablespace.dbf' 
SIZE 100M 
AUTOEXTEND ON 
NEXT 50M 
MAXSIZE UNLIMITED 
EXTENT MANAGEMENT LOCAL;



CREATE TABLE  rol(
	id int PRIMARY KEY,
	name varchar(50) NOT NULL
) tablespace data_tablespace;

CREATE TABLE users(
	id int PRIMARY KEY,
	username varchar(50) NOT NULL,
	password varchar(255) NOT NULL,
	email varchar(50) NOT NULL,
	email_confirmed NUMBER(1),
	rol_id int NOT NULL,
	CONSTRAINT users_rol_id FOREIGN KEY (rol_id) REFERENCES rol(id)	
) tablespace data_tablespace;


CREATE TABLE blood_type(
	id int PRIMARY KEY ,
	name varchar2(5) NOT NULL ,
	description varchar2(100)
) tablespace data_tablespace;

CREATE TABLE specialty(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT NULL
) tablespace data_tablespace;

CREATE TABLE presc_status(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
) tablespace data_tablespace;


CREATE TABLE dis_class(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
) tablespace data_tablespace;

CREATE TABLE med_brand(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
) tablespace data_tablespace;

CREATE TABLE pharma_form(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL,
	description varchar2(100) NOT null
) tablespace data_tablespace;

CREATE TABLE dose_unit
(
	id int PRIMARY KEY ,
	name varchar2(20) NOT NULL ,
	description varchar2(100) NOT null
) tablespace data_tablespace;

CREATE TABLE sex
(
	id int PRIMARY KEY ,
	name varchar2(10) NOT NULL 
) tablespace data_tablespace;


CREATE TABLE doctor(
	cui varchar2(13) PRIMARY KEY,
	name varchar2(100) NOT null,
	birthday DATE NOT null,
	sex_id int NOT NULL,
	speciality_Id int NOT NULL,
	constraint doctor_sex_id foreign key (sex_id) references sex (id),
	constraint doctor_speciality_id foreign key (speciality_id) references specialty(id)
) tablespace data_tablespace;

CREATE TABLE patient(
	cui varchar2(13) PRIMARY KEY,
	name varchar2(100) NOT null,
	birthday DATE NOT null,
	sex_id int NOT NULL,
	blood_Type_id int NOT NULL,
	constraint patient_sex_id foreign key (sex_id) references sex (id),
	constraint patient_blood_Type_id foreign key (blood_Type_id) references blood_type(id)
) tablespace data_tablespace;

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
) tablespace data_tablespace;

CREATE TABLE diseases(
	id int PRIMARY KEY,
	name varchar2(30) NOT NULL,
	description varchar2(200) NOT NULL,
	sintomas varchar2(300) NOT NULL,
	classification_id int NOT NULL,
	CONSTRAINT disease_dis_class_id FOREIGN KEY (classification_id) REFERENCES dis_class(id)
) tablespace data_tablespace;

CREATE TABLE pharma_form_dose_unit(
	id int PRIMARY KEY,
	pharma_form_id int NOT NULL,
	dose_unit_id int NOT NULL,
	CONSTRAINT pfdu_pharma_form_id FOREIGN KEY (pharma_form_id) REFERENCES pharma_form(id), 
	CONSTRAINT pfdu_dose_unit_id FOREIGN KEY (dose_unit_id) REFERENCES dose_unit(id)
) tablespace data_tablespace;

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
) tablespace data_tablespace;

CREATE TABLE diseases_medicine (
	disease_id int NOT NULL,
	medicine_id int NOT NULL,
	recommended_dosage float NOT null,
	recommended_frecuency float NOT NULL,
	CONSTRAINT dm_disease_id FOREIGN KEY (disease_id) REFERENCES diseases(id),
	CONSTRAINT dm_medicine_id FOREIGN KEY (medicine_id) REFERENCES medicine(id)
) tablespace data_tablespace; 


CREATE TABLE diagnosed_disease(
	id int PRIMARY KEY,
	consultation_id int NOT NULL,
	disease_id int NOT NULL,
	CONSTRAINT dd_consultation_id FOREIGN KEY (consultation_id) REFERENCES consultation(id),
	CONSTRAINT dd_disease_id FOREIGN KEY (disease_id) REFERENCES diseases(id)
) tablespace data_tablespace;

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
) tablespace data_tablespace;

CREATE TABLE binnacle_header(
	id int PRIMARY KEY,
	table_name varchar(20) NOT NULL,
	operation char(1) NOT NULL,
	day_operation DATE NOT NULL DEFAULT CURRENT_DATE,
	register_id int NOT null,
	user_id int,
	ip varchar(20) NOT null,
	CONSTRAINT b_header_user_id FOREIGN KEY (user_id) REFERENCES users(id) 
) tablespace binnacle_tablespace;


CREATE TABLE binnacle_body(
	id int PRIMARY KEY,
	field varchar(20) NOT null,
	previous_value varchar(255),
	new_value varchar(255) NOT null,
	binnacle_header_id int NOT NULL,
	CONSTRAINT binn_body_binn_header_id FOREIGN KEY (binnacle_header_id) REFERENCES binnacle_header(id)
) tablespace binnacle_tablespace;

BEGIN 

END;


BEGIN
	pro_add_binnacle_data('doctor');
	pro_add_binnacle_data('patient');
	pro_add_binnacle_data('diseases_medicine');
	pro_create_increment('binnacle_header');
	pro_create_increment('binnacle_body');
	pro_create_trigger_autoincrement('binnacle_body');
	pro_config_table('rol');
	pro_config_table('users');
	pro_config_table('blood_type');
	pro_config_table('specialty');
	pro_config_table('presc_status');
	pro_config_table('dis_class');
	pro_config_table('med_brand');
	pro_config_table('pharma_form');
	pro_config_table('dose_unit');
	pro_config_table('sex');
	pro_config_table('consultation');
	pro_config_table('diseases');
	pro_config_table('pharma_form_dose_unit');
	pro_config_table('medicine');
	pro_config_table('diagnosed_disease');
	pro_config_table('recommended_medication');

	--Creamos los triggers para las tablas que se insertaran en bitacora
	pro_create_trigger_binnacle('users', 'ID');
	pro_create_trigger_binnacle('rol', 'ID');
	pro_create_trigger_binnacle('consultation', 'ID');
	pro_create_trigger_binnacle('doctor', 'CUI');
	pro_create_trigger_binnacle('patient', 'CUI');
	pro_create_trigger_binnacle('medicine', 'ID');
	pro_create_trigger_binnacle('diseases', 'ID');
	pro_create_trigger_binnacle('recommended_medication', 'ID');
    pro_create_trigger_binnacle('diagnosed_disease', 'ID');
    pro_create_trigger_binnacle('pharma_form_dose_unit', 'ID');
	pro_create_trigger_binnacle(
	    'diseases_medicine',
	    'disease_id,medicine_id'
		);
END;

CREATE OR REPLACE TRIGGER TRG_RECOMMENDED_MED_CORRECT
BEFORE INSERT OR UPDATE ON RECOMMENDED_MEDICATION 
FOR EACH ROW
DECLARE 
    CURSOR disease_found IS 
        SELECT dm.* 
        FROM DIAGNOSED_DISEASE dd 
        JOIN DISEASES_MEDICINE dm 
        ON dd.disease_id = dm.disease_id 
        WHERE dd.ID = :NEW.diagnosed_disease_id 
        AND dm.MEDICINE_ID = :NEW.MEDICINE_ID;

    v_disease_med diseases_medicine%ROWTYPE; 
BEGIN 
    OPEN disease_found;

    FETCH disease_found INTO v_disease_med;

    IF disease_found%FOUND THEN
        IF :NEW.DOSE > v_disease_med.recommended_dosage * 2 THEN
            RAISE_APPLICATION_ERROR(-20001, 'La dosis recomendada supera el doble que la que recomienda la farmacéutica.');
        END IF;
    
        IF :NEW.FREQUENCY_HRS < v_disease_med.recommended_frecuency / 2 THEN
            RAISE_APPLICATION_ERROR(-20001, 'La frecuencia recomendada es menor a la mitad que recomienda la farmacéutica.');
        END IF;
    
        DBMS_OUTPUT.PUT_LINE('Medicamento encontrado para la enfermedad diagnosticada.');
    
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'El medicamento no está asociado con la enfermedad diagnosticada.');
    END IF;

    CLOSE disease_found;
END;






-- Inserts 
INSERT INTO rol (name) 
VALUES ('Admin'), 
       ('Doctor'), 
       ('Paciente');

INSERT INTO users (username, password, email, email_confirmed, rol_id) 
VALUES ('admin_user', 'admin123', 'admin@ejemplo.com', 1, 1), 
       ('doctor_user', 'doc123', 'doctor@ejemplo.com', 1, 2), 
       ('paciente_user', 'paciente123', 'paciente@ejemplo.com', 1, 3);

      
INSERT INTO blood_type (name, description) 
VALUES ('A+', 'Tipo de sangre A positivo'), 
       ('B+', 'Tipo de sangre B positivo'), 
       ('O-', 'Tipo de sangre O negativo');

INSERT INTO sex (name) 
VALUES ('Masculino'), 
       ('Femenino');
      
INSERT INTO specialty (name, description) 
VALUES ('Cardiología', 'Especialista en corazón'), 
       ('Neurología', 'Especialista en cerebro'), 
       ('Pediatría', 'Especialista en niños');
      
INSERT INTO doctor (cui, name, birthday, sex_id, speciality_Id) 
VALUES ('1234567890123', 'Dr. Juan Pérez', TO_DATE('1975-01-10', 'YYYY-MM-DD'), 1, 1), 
       ('1234567890124', 'Dra. María López', TO_DATE('1980-05-20', 'YYYY-MM-DD'), 2, 2), 
       ('1234567890125', 'Dr. Alex Blanco', TO_DATE('1990-03-15', 'YYYY-MM-DD'), 1, 3);

      
INSERT INTO patient (cui, name, birthday, sex_id, blood_type_id) 
VALUES ('9876543210123', 'Paciente A', TO_DATE('1995-07-10', 'YYYY-MM-DD'), 1, 1), 
       ('9876543210124', 'Paciente B', TO_DATE('2000-09-20', 'YYYY-MM-DD'), 2, 2), 
       ('9876543210125', 'Paciente C', TO_DATE('1985-12-30', 'YYYY-MM-DD'), 1, 3);


      
INSERT INTO med_brand (name, description) 
VALUES ('Pfizer', 'Compañía farmacéutica Pfizer'), 
       ('Moderna', 'Compañía farmacéutica Moderna'), 
       ('AstraZeneca', 'Compañía farmacéutica AstraZeneca');

INSERT INTO pharma_form (name, description) 
VALUES ('Tableta', 'Forma de administración en tabletas'), 
       ('Inyección', 'Forma de administración en inyección'), 
       ('Jarabe', 'Forma de administración en jarabe');

INSERT INTO dose_unit (name, description) 
VALUES ('mg', 'Miligramos'), 
       ('ml', 'Mililitros'), 
       ('g', 'Gramos');
      
INSERT INTO pharma_form_dose_unit (pharma_form_id, dose_unit_id) 
VALUES (1, 1), -- Tableta en mg
       (2, 2), -- Inyección en ml
       (3, 2); -- Jarabe en ml

INSERT INTO dis_class (name, description) 
VALUES ('Metabólica', 'Enfermedades metabólicas'), 
       ('Cardiovascular', 'Enfermedades del corazón'), 
       ('Respiratoria', 'Enfermedades respiratorias');

INSERT INTO presc_status (name, description) 
VALUES ('Pendiente', 'Prescripción pendiente de ser completada'), 
       ('Completada', 'Prescripción completada'), 
       ('Cancelada', 'Prescripción cancelada');


INSERT INTO diseases (name, description, sintomas, classification_id) 
VALUES ('Diabetes', 'Enfermedad metabólica', 'Sed excesiva, fatiga', 1), 
       ('Hipertensión', 'Presión arterial alta', 'Dolor de cabeza, mareo', 2), 
       ('Asma', 'Enfermedad respiratoria', 'Dificultad para respirar', 3);

INSERT INTO medicine (name, brand_id, description, composition, pfdu_id, recommended_amount, indications, adverse_effects) 
VALUES ('Metformina', 1, 'Medicamento para la diabetes', 'Clorhidrato de metformina', 1, 500, 'Tratamiento para la diabetes tipo 2', 'Náuseas, diarrea'), 
       ('Lisinopril', 2, 'Medicamento para la hipertensión', 'Lisinopril', 2, 10, 'Tratamiento para la hipertensión', 'Mareo, fatiga'), 
       ('Salbutamol', 3, 'Medicamento para el asma', 'Salbutamol', 3, 2.5, 'Tratamiento para el asma', 'Temblor, dolor de cabeza');

INSERT INTO diseases_medicine (disease_id, medicine_id, recommended_dosage, recommended_frecuency) 
VALUES (4, 1, 500, 12),  -- Diabetes -> Metformina
       (5, 2, 10, 24),   -- Hipertensión -> Lisinopril
       (6, 3, 2.5, 6);   -- Asma -> Salbutamol

INSERT INTO consultation (date_visit, general_comments, doctor_cui, patient_cui, presc_status_id) 
VALUES (TO_DATE('2024-01-15', 'YYYY-MM-DD'), 'Revisión general', '1234567890123', '9876543210123', 1), 
       (TO_DATE('2024-01-20', 'YYYY-MM-DD'), 'Consulta de seguimiento', '1234567890124', '9876543210124', 2), 
       (TO_DATE('2024-02-05', 'YYYY-MM-DD'), 'Primera visita', '1234567890125', '9876543210125', 3);

INSERT INTO diagnosed_disease (consultation_id, disease_id) 
VALUES (1, 4),  -- Consulta 1 -> Diabetes
       (2, 5),  -- Consulta 2 -> Hipertensión
       (3, 6);  -- Consulta 3 -> Asma

INSERT INTO recommended_medication 
(diagnosed_disease_id, dose, frequency_hrs, duration_days, additional_instructions, medicine_id) 
VALUES (4, 500, 12, 30, 'Tomar con las comidas', 1),  -- Metformina para Diabetes
       (5, 10, 24, 60, 'Tomar a la misma hora todos los días', 2), -- Lisinopril para Hipertensión
       (6, 2.5, 6, 15, 'Usar en caso de dificultad para respirar', 3); -- Salbutamol para Asma

--Updates
UPDATE DOCTOR  SET NAME ='Dr Meme', UPDATE_USER_ID=1 , IP_UPDATE ='1.111.111.11' WHERE CUI ='1234567890123';
UPDATE ROL SET NAME ='Administrador', UPDATE_USER_ID =2, IP_UPDATE ='23.232.322' WHERE ID =1 ;
UPDATE  PATIENT SET NAME ='Nivocado Avocado', BIRTHDAY = TO_DATE('1985-12-30', 'YYYY-MM-DD'), UPDATE_USER_ID =3 , IP_UPDATE ='12.323.555' WHERE CUI ='9876543210123';

--Funciones
--Calcula edades
CREATE OR REPLACE FUNCTION calculate_age(birthday DATE)
RETURN NUMBER
IS
    v_age NUMBER;
BEGIN
    v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, birthday) / 12);
    RETURN v_age;
END;

SELECT calculate_age(birthday) FROM patient WHERE cui = '9876543210123';

-- Verifica si cierta medicina esta disponible para cierta enfermedad
CREATE OR REPLACE FUNCTION is_medicine_available(disease_id_found NUMBER , medicine_id_found NUMBER )
RETURN VARCHAR2
IS
    v_count NUMBER ;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM diseases_medicine
    WHERE disease_id = disease_id_found AND medicine_id = medicine_id_found;

    IF v_count > 0 THEN
        RETURN 'Disponible';
    ELSE
        RETURN 'No disponible';
    END IF;
END;

SELECT is_medicine_available(10,5) FROM dual;

--Obtener el total de consultas de un doctor
CREATE OR REPLACE FUNCTION total_consultations_by_doctor(doctor_cui_found IN VARCHAR2)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM consultation
    WHERE doctor_cui = doctor_cui_found;

    RETURN v_count;
END;

--Funcion que devuelve las enfermedades que han sido diagnosticadas de un paciente
CREATE OR REPLACE FUNCTION get_diagnosed_diseases(patient_cui_found IN VARCHAR2)
RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT c.id AS id_consulta,c.date_visit date_visit, c.create_at create_at ,d.name, d.description, m.NAME , rm.FREQUENCY_HRS , rm.DURATION_DAYS, rm.ADDITIONAL_INSTRUCTIONS , rm.DOSE 
    FROM diagnosed_disease dd
    JOIN consultation c ON dd.consultation_id = c.id
    JOIN diseases d ON dd.disease_id = d.id
    JOIN RECOMMENDED_MEDICATION rm ON dd.ID = rm.DIAGNOSED_DISEASE_ID
    JOIN MEDICINE m  ON m.ID = rm.MEDICINE_ID 
    WHERE c.patient_cui = patient_cui_found ;
    RETURN v_cursor;
END;

SELECT get_diagnosed_diseases('9876543210123')  FROM dual;

--Funcion que devuelve la trazabilidad de una consulta
CREATE OR REPLACE FUNCTION get_consultation_status_trail(consultation_id_found IN NUMBER)
RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT bh.day_operation,
           PS2.NAME  AS status_previous,
		   ps.NAME AS status_new
    FROM binnacle_header bh
    JOIN binnacle_body bb ON bh.id = bb.binnacle_header_id
    JOIN PRESC_STATUS ps ON ps.ID = bb.NEW_VALUE 
    JOIN PRESC_STATUS ps2 ON ps2.ID = bb.PREVIOUS_VALUE  
    WHERE bh.table_name = 'consultation'
      AND bh.register_id = TO_CHAR(consultation_id_found) 
      AND bb.field = 'PRESC_STATUS_ID'  
    ORDER BY bh.day_operation ASC;

    RETURN v_cursor;
END;

UPDATE CONSULTATION SET PRESC_STATUS_ID =2, UPDATE_USER_ID =3, IP_UPDATE ='123.123.123' WHERE ID =1;
      
SELECT get_consultation_status_trail(1) FROM dual;



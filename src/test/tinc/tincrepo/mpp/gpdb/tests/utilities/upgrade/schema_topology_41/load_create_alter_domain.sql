create database db_test_bed;
\c db_test_bed
CREATE DOMAIN domain_us_zip_code AS TEXT CHECK ( VALUE ~ E'\\d{5}$' OR VALUE ~ E'\\d{5}-\\d{4}$');
CREATE DOMAIN domain_1 AS int DEFAULT 1 CONSTRAINT cons_not_null NOT NULL;
CREATE DOMAIN domain_2 AS int CONSTRAINT cons_null NULL;
CREATE DOMAIN domain_3 AS TEXT ;

CREATE ROLE domain_owner;
CREATE SCHEMA domain_schema;

ALTER DOMAIN domain_2 SET DEFAULT 1;
ALTER DOMAIN domain_2 DROP  DEFAULT;
ALTER DOMAIN domain_2 SET NOT NULL;
ALTER DOMAIN domain_2 DROP NOT NULL;
ALTER DOMAIN domain_3 ADD CONSTRAINT  domain_constraint3 CHECK (char_length(VALUE) = 5) ;
ALTER DOMAIN domain_3 DROP CONSTRAINT  domain_constraint3 RESTRICT;
ALTER DOMAIN domain_3 ADD CONSTRAINT  domain_constraint3 CHECK (char_length(VALUE) = 5);
ALTER DOMAIN domain_3 DROP CONSTRAINT domain_constraint3 CASCADE;
ALTER DOMAIN domain_3 OWNER TO domain_owner;
ALTER DOMAIN domain_3 SET SCHEMA domain_schema;

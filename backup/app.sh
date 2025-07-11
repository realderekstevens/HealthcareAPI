#!/bin/bash

PSQL="psql -X --username=postgres --dbname=medicare --tuples-only -c"
PSQL_CreateDatabase="psql -X --username=postgres --dbname=postgres --tuples-only -c"

MAIN_MENU(){
  clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Welcome to" "     HealthcareCLI"
  OPTIONS=$(gum choose --header "Main Menu: " "Importer" "Inserter" "Query" "Database" "Git" "PostgREST" "Arch Linux" "Exit")
    case "$OPTIONS" in
     "Importer") IMPORTER_MENU ;;
     "Inserter") INSERT_DATA_MENU ;;
     "Query") MAIN_MENU ;;
     "Database") DATABASE_MANAGEMENT_MENU ;;
     "Git") GITHUB_MANAGEMENT_MENU ;;
     "PostgREST") POSTGREST_MANAGEMENT_MENU ;;
     "Arch Linux") ARCH_LINUX_MANAGEMENT_MENU ;;
     "Exit") EXIT ;;
    esac
}

##### ##### IMPORTER ##### #####

IMPORTER_MENU(){
  clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Data Import Menu"
  OPTIONS=$(gum choose --header "Expiditied Testing Importer Menu: " \
    "Return to Main Menu" \
    "Do the thing" \
    "Drop Database Medicare" \
    "Drop Table Master" \
    "Drop Table Contracts 06.15.2025" \
    "Drop Table Enrollments 06.15.2025" \
    "Create Table Master" \
    "Create Table Contracts 06.15.2025" \
    "Create Table Enrollments 06.15.2025" \
    "Download monthly-enrollment-cpsc-2025-06.zip" \
    "Upload CPSC_Contract_Info_2025_06.csv" \
    "Upload CPSC_Enrollment_Info_2025_06.csv" \
    "Cross Merge into Master" \
    "Delete CPSC_Contract_Info_2025_06.csv" \
    "Delete CPSC_Enrollment_Info_2025_06.csv" \
    "Delete monthly-enrollment-cpsc-2025-06.zip")
    case "$OPTIONS" in
     "Do the thing") DO_THE_THING ;;
     "Drop Database Medicare") DELETE_DATABASE ;;
     "Return to Main Menu") MAIN_MENU ;;
     "Drop Table Master") MAIN_MENU ;; 
     "Drop Table Contracts 06.15.2025") DELETE_TABLE_CONTRACTS ;;
     "Drop Table Enrollments 06.15.2025") DELETE_TABLE_ENROLLMENTS ;;
     "Create Table Master") MAIN_MENU ;;
     "Create Table Contracts Schema 06.15.2025") MAIN_MENU ;;
     "Create Table Enrollments Schema 06.15.2025") MAIN_MENU ;;
     "Download monthly-enrollment-cpsc-2025-06.zip") MAIN_MENU ;;
     "UPLOAD CPSC_Contract_Info_2025_06") MAIN_MENU ;;
     "UPLOAD CPSC_Enrollment_Info_2025_06") MAIN_MENU ;;
     "Cross Merge into Master") CROSS_MERGE_06_2025 ;;
     "DELETE CPSC_Contract_Info_2025_06.csv") MAIN_MENU ;;
     "DELETE CPSC_Enrollment_Info_2025_06.csv") MAIN_MENU ;;
     "DELETE monthly-enrollment-cpsc-2025-06.zip") MAIN_MENU ;;
    esac
}

INSERT_DATA_MENU(){
  clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Welcome to" "     HealthcareCLI"
  OPTIONS=$(gum choose --header "Main Menu: " "Importer" "Query" "Database" "Git" "PostgREST" "Arch Linux" "Exit")
    case "$OPTIONS" in
     "Import Enrollments 06 2025") IMPORT_ENROLLMENTS_2025_06 ;;
     "Import Contracts 06 2025") IMPORT_CONTRACTS_2025_06 ;;
     "Return to Main Menu") MAIN_MENU ;;
    esac
}

IMPORT_ENROLLMENTS_2025_06(){
  psql -d medicare -U postgres -c "\COPY enrollments(contract_id, plan_id, ssa_state_county_code, fips_state_county_code, state, county, enrollment) from /home/dude/CPSC_Enrollment_Info_2025_06.csv delimiter ',' csv header;"
}

IMPORT_CONTRACTS_2025_06(){
  psql -d medicare -U postgres -c "\COPY contracts(contract_id, plan_id, organization_type, plan_type, offers_part_d, snp_plan, eghp, organization_name, organization_marketing_name, plan_name, parent_organization, contract_effective_date) from /home/dude/CPSC_Contract_Info_2025_06.csv delimiter ',' csv header;"
}

UNZIP_CPSC_ENROLLMENT_2025_06(){
  set -e # Exit on any error
  ZIP_FILE="/home/dude/github/MedicareAPI/zip/cpsc_enrollment_2025_06.zip"
  CSV_DIR="/home/dude/github/MedicareAPI/csv/"
  # Check if zip file exists
  if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: Zip file $ZIP_FILE does not exist"
    exit 1
  fi

  # Create target directory if it doesn't exist
  mkdir - p "$CSV_DIR"

  # Run unzip and capture output/errors
  unzip -o "$ZIP_FILE" -d "$CSV_DIR" 2>&1 | tee unzip.log
  if [ $? -ne 0 ]; then
    echo "Error: Failed to unzip $ZIP_FILE to $CSV_DIR"
    cat unzip.log
    exit 1
  fi

echo "Successfully unzipped $ZIP_FILE to $CSV_DIR"
}

MERGE_TABLES() {
    $PSQL "CREATE TABLE merged_contracts_enrollments (
        postgres_id SERIAL PRIMARY KEY(10),
        contract_id VARCHAR(10),
        plan_id VARCHAR(10),
        organization_type VARCHAR,
        plan_type VARCHAR,
        offers_part_d BOOLEAN,
        snp_plan BOOLEAN,
        eghp BOOLEAN,
        organization_name VARCHAR,
        organization_marketing_name VARCHAR,
        plan_name VARCHAR,
        parent_organization VARCHAR,
        contract_effective_date VARCHAR,
        ssa_state_county_code VARCHAR(10),
        fips_state_county_code VARCHAR(10),
        state VARCHAR(2),
        county VARCHAR(50),
        enrollment VARCHAR(100),
        PRIMARY KEY (contract_id, plan_id)
    );"
    $PSQL "INSERT INTO merged_contracts_enrollments
           SELECT 
               CONCAT(c.contract_id, '_', c.plan_id) AS primary_id,
               c.contract_id,
               c.plan_id,
               c.organization_type,
               c.plan_type,
               c.offers_part_d,
               c.snp_plan,
               c.eghp,
               c.organization_name,
               c.organization_marketing_name,
               c.plan_name,
               c.parent_organization,
               c.contract_effective_date,
               e.ssa_state_county_code,
               e.fips_state_county_code,
               e.state,
               e.county,
               e.enrollment
           FROM 
               contracts c
           INNER JOIN 
               enrollments e
           ON 
               c.contract_id = e.contract_id 
               AND c.plan_id = e.plan_id;"
    echo "Merged contracts and enrollments into merged_contracts_enrollments"
}

DO_THE_THING(){
  DELETE_DATABASE
  CREATE_DATABASE
  CREATE_TABLE_CONTRACTS
  CREATE_TABLE_ENROLLMENTS
  CREATE_TABLE_MASTER
  IMPORT_CONTRACTS_2025_06
  IMPORT_ENROLLMENTS_2025_06
  MERGE_TABLES
}













##### ##### DATABASE ##### #####

DATABASE_MANAGEMENT_MENU(){
  clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Database Management Menu"
  OPTIONS=$(gum choose --header "Database & Table Management Menu: " "Return to Main Menu" "Schemas" "Create" "Delete" "Insert" "Select" "Update")
    case "$OPTIONS" in
     "Return to Main Menu") MAIN_MENU ;;
     "Schemas") LIST_SCHEMA_MENU ;;
     "Create") CREATE_DATABASE_AND_TABLES_MENU ;;
     "Delete") DELETE_DATABASE_MANAGEMENT_MENU ;;
     "Insert") INSERT_DATA_MENU ;;
     "Select") SELECT_DATA_MENU ;;
     "Update") UPDATE_DATA_MENU ;;
    esac
}

##### ##### LINUX ##### #####

ARCH_LINUX_MANAGEMENT_MENU(){
	clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Database Management Menu"
  OPTIONS=$(gum choose --header "Database & Table Management Menu: " "Return to Main Menu" "System-Wide Update")
    case "$OPTIONS" in
     "Return to Main Menu") MAIN_MENU ;;
     "System Update") ARCH_SYSTEM_UPDATE ;;
    esac
}

ARCH_SYSTEM_UPDATE(){
  pacman -Syu
  ARCH_LINUX_MANAGEMENT_MENU
}

##### ##### ##### ##### #####

POSTGREST_MANAGEMENT_MENU(){
	if [[ $1 ]]
	then
		echo -e "\n$1"
	fi
	clear
	echo -e "\n~~~~~ PostgREST Management Menu ~~~~~"
	echo -e "\n0.) Return to Main Menu\n1.) Create Schema 'api'\n2.) Create Table 'api.todos'\n3.) Create Role 'web_anon'\n4.) Create role 'authenticator'\n5.) Create 'tutorial.conf'\n6.) Run PostgREST Tutorial\n7.) Create Role Todo User\n"
	echo "ENTER COMMAND: "
	read POSTGREST_MANAGEMENT_MENU_SELECTION
	case $POSTGREST_MANAGEMENT_MENU_SELECTION in
	0) MAIN_MENU ;;
	1) POSTGREST_CREATE_SCHEMA_API ;;
	2) POSTGREST_CREATE_TABLE_API_TODOS ;;
	3) POSTGREST_CREATE_ROLE_WEBANON ;;
	4) POSTGREST_CREATE_ROLE_AUTHENTICATOR ;;
	5) POSTGREST_CREATE_TUTORIAL_CONF ;;
	6) POSTGREST_START_TUTORIAL_SERVER ;;
	7) POSTGREST_CREATE_ROLE_TODO_USER ;;
	*) POSTGREST_MANAGEMENT_MENU "Please enter a valid option." ;;
esac
}

POSTGREST_CREATE_SCHEMA_API(){
	psql -d medicare -U postgres -c "create schema api;"
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Created Schema api;"
}

POSTGREST_CREATE_TABLE_API_TODOS(){
	psql -d medicare -U postgres -c "create table api.todos (id int primary key generated by default as identity, 
		done boolean not null default false,
		task text not null,
		due timestamptz);"
	psql -d medicare -U postgres -c "insert into api.todos (task) values
		('finish tutorial 0'), 
		('pat self on back');"
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Created table api.todos"
}

POSTGREST_CREATE_ROLE_WEBANON(){
	psql -d medicare -U postgres -c "create role web_anon nologin;
		grant usage on schema api to web_anon;
		grant select on api.todos to web_anon;"
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Executed Command"
}

POSTGREST_CREATE_ROLE_AUTHENTICATOR(){
	psql -d medicare -U postgres -c "create role authenticator noinherit login password 'mysecretpassword';
		grant web_anon to authenticator;"
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Executed Command"
}

POSTGREST_CREATE_TUTORIAL_CONF(){
	touch tutorial.conf
	echo "db-uri = 'postgres://authenticator:mysecretpassword@localhost:5432/postgres'" >> tutorial.conf
	echo "db-schemas = 'api'" >> tutorial.conf
	echo "db-anon-role = 'web_anon'" >> tutorial.conf
	echo "server-port = 80" >> tutorial.conf
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Executed Command"
}

POSTGREST_START_TUTORIAL_SERVER(){
	postgrest tutorial.conf
}


POSTGREST_CREATE_ROLE_TODO_USER(){
	psql -d medicare -U postgres -c "create role todo_user nologin;
	grant todo_user to authenticator;
	grant usage on schema api to todo_user;
	grant all on api.todos to todo_user;"
	sleep 2
	POSTGREST_MANAGEMENT_MENU "Executed Command"
}

##### ########## ##### ##### ##### #####

GITHUB_MANAGEMENT_MENU(){
  clear
  gum style \
    --border thick \
    --margin ".5" \
    --padding "1 2" \
    --border-foreground "#04B575" \
    "Database Management Menu"
  OPTIONS=$(gum choose --header "Github Management Menu: " "Return to Main Menu" "Commit" "Push")
    case "$OPTIONS" in
     "Return to Main Menu") MAIN_MENU ;;
     "Add app.sh") GITHUB_ADD ;;
     "Commit") GITHUB_COMMIT ;;
     "Push") GITHUB_PUSH ;;
    esac
}

GITHUB_ADD(){
	git add app.sh
	GITHUB_MANAGEMENT_MENU
}

GITHUB_COMMIT(){
	git commit -m "Committed from the command line"
	GITHUB_MANAGEMENT_MENU
}

GITHUB_PUSH(){
	git push -u origin HEAD
	GITHUB_MANAGEMENT_MENU
}

##### ##### ##### ##### #####

LIST_SCHEMA_MENU(){
   if [[ $1 ]]
   then
      echo -e "\n$1"
   fi
   echo -e "\n~~~~~ Schema Menu ~~~~~"
   echo -e "\n0. Return To Database Management Menu\n1. List Databases\n2. List Tables\n3. List Table contracts\n4. List Table enrollments\n"
   echo "Enter Command: "
   read DATABASE_MANAGEMENT_MENU_SELECTION
   case $DATABASE_MANAGEMENT_MENU_SELECTION in
   0) DATABASE_MANAGEMENT_MENU ;;
   1) LIST_DATABASES ;;
   2) LIST_TABLES ;;
   3) LIST_TABLE_CONTRACTS ;;
   4) LIST_TABLE_ENROLLMENTS ;;
   *) LIST_SCHEMA_MENU "Please enter a valid option." ;;
esac
}

LIST_DATABASES(){
	$PSQL_CreateDatabase "\l"
	LIST_SCHEMA_MENU "Listed Databases"
}

LIST_TABLES(){
	$PSQL "\dt+"
	LIST_SCHEMA_MENU "Listed Tables"
}

LIST_TABLE_CONTRACTS(){
	$PSQL "\d contracts"
	LIST_SCHEMA_MENU "Listed Table contracts"
}

LIST_TABLE_ENROLLMENTS(){
	$PSQL "\d enrollments"
	LIST_SCHEMA_MENU "Listed Table enrollments"
}

##### ##### CREATE ##### #####

CREATE_DATABASE_AND_TABLES_MENU(){
   if [[ $1 ]]
   then
      echo -e "\n$1"
   fi
   echo -e "\n~~~~~ Create Database & Tables Menu ~~~~~"
   echo -e "\n0. Return To Database Management Menu\n1. Create Database medicare\n2. Create Table contracts\n3. Create Table enrollments"
   echo "Enter Command: "
   read DATABASE_MANAGEMENT_MENU_SELECTION
   case $DATABASE_MANAGEMENT_MENU_SELECTION in
   0) DATABASE_MANAGEMENT_MENU ;;
   1) CREATE_DATABASE ;;
   2) CREATE_TABLE_CONTRACTS ;;
   3) CREATE_TABLE_ENROLLMENTS ;;
   *) CREATE_DATABASE_AND_TABLES_MENU "Please enter a valid option." ;;
esac
}

CREATE_TABLE_CONTRACTS() {
    $PSQL "CREATE TABLE contracts();"
    $PSQL "ALTER TABLE contracts ADD COLUMN postgres_id SERIAL PRIMARY KEY;"
    $PSQL "ALTER TABLE contracts ADD COLUMN contract_id VARCHAR(10);"
    $PSQL "ALTER TABLE contracts ADD COLUMN plan_id VARCHAR(10);"
    $PSQL "ALTER TABLE contracts ADD COLUMN organization_type VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN plan_type VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN offers_part_d BOOLEAN;"
    $PSQL "ALTER TABLE contracts ADD COLUMN snp_plan BOOLEAN;"
    $PSQL "ALTER TABLE contracts ADD COLUMN eghp BOOLEAN;"
    $PSQL "ALTER TABLE contracts ADD COLUMN organization_name VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN organization_marketing_name VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN plan_name VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN parent_organization VARCHAR;"
    $PSQL "ALTER TABLE contracts ADD COLUMN contract_effective_date VARCHAR;"
    echo "Created Tables contracts & Altered!!!"
}

CREATE_TABLE_ENROLLMENTS() {
    $PSQL "CREATE TABLE enrollments();"
    $PSQL "ALTER TABLE enrollments ADD COLUMN postgres_id SERIAL PRIMARY KEY;"
    $PSQL "ALTER TABLE enrollments ADD COLUMN contract_id VARCHAR(10);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN plan_id VARCHAR(10);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN ssa_state_county_code VARCHAR(10);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN fips_state_county_code VARCHAR(10);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN state VARCHAR(2);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN county VARCHAR(50);"
    $PSQL "ALTER TABLE enrollments ADD COLUMN enrollment VARCHAR(100);"
    echo "Created Table enrollments!!!"
}

CREATE_TABLE_MASTER() {
    $PSQL "CREATE TABLE master();"
    $PSQL "ALTER TABLE master ADD COLUMN postgres_id SERIAL PRIMARY KEY;"
    $PSQL "ALTER TABLE master ADD COLUMN contract_id VARCHAR(10);"
    $PSQL "ALTER TABLE master ADD COLUMN plan_id VARCHAR(10);"
    $PSQL "ALTER TABLE master ADD COLUMN ssa_state_county_code VARCHAR(10);"
    $PSQL "ALTER TABLE master ADD COLUMN fips_state_county_code VARCHAR(10);"
    $PSQL "ALTER TABLE master ADD COLUMN state VARCHAR(2);"
    $PSQL "ALTER TABLE master ADD COLUMN county VARCHAR(50);"
    $PSQL "ALTER TABLE master ADD COLUMN enrollment VARCHAR(100);"
    $PSQL "ALTER TABLE master ADD COLUMN organization_type VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN plan_type VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN offers_part_d BOOLEAN;"
    $PSQL "ALTER TABLE master ADD COLUMN snp_plan BOOLEAN;"
    $PSQL "ALTER TABLE master ADD COLUMN eghp BOOLEAN;"
    $PSQL "ALTER TABLE master ADD COLUMN organization_name VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN organization_marketing_name VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN plan_name VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN parent_organization VARCHAR;"
    $PSQL "ALTER TABLE master ADD COLUMN contract_effective_date VARCHAR;"
    echo "Created Table master!!!"
}

CREATE_DATABASE(){
	$PSQL_CreateDatabase "CREATE DATABASE medicare;"
}

OLD_CREATE_TABLE_CONTRACTS(){
	$PSQL "CREATE TABLE contracts();"
	$PSQL "ALTER TABLE contracts ADD COLUMN postgres_id SERIAL PRIMARY KEY ;"
	$PSQL "ALTER TABLE contracts ADD COLUMN contract_id VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN plan_id SMALLINT;"
	$PSQL "ALTER TABLE contracts ADD COLUMN organization_type VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN plan_type VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN offers_part_d BOOLEAN;"
	$PSQL "ALTER TABLE contracts ADD COLUMN snp_plan BOOLEAN;"
	$PSQL "ALTER TABLE contracts ADD COLUMN eghp BOOLEAN;"
	$PSQL "ALTER TABLE contracts ADD COLUMN organization_name VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN organization_marketing_name VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN plan_name VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN parent_organization VARCHAR;"
	$PSQL "ALTER TABLE contracts ADD COLUMN contract_effective_date DATE;"
	CREATE_DATABASE_AND_TABLES_MENU "Created Tables contracts & Altered"
}

OLD_CREATE_TABLE_ENROLLMENTS(){
	$PSQL "CREATE TABLE enrollments();"
	$PSQL "ALTER TABLE enrollments ADD COLUMN postgres_id SERIAL PRIMARY KEY;"
	$PSQL "ALTER TABLE enrollments ADD COLUMN contract_id VARCHAR(10);"
	$PSQL "ALTER TABLE enrollments ADD COLUMN plan_id SMALLINT;"
	$PSQL "ALTER TABLE enrollments ADD COLUMN ssa_state_county_code VARCHAR(10);"
	$PSQL "ALTER TABLE enrollments ADD COLUMN fips_state_county_code VARCHAR(10);"
	$PSQL "ALTER TABLE enrollments ADD COLUMN state VARCHAR(2);"
	$PSQL "ALTER TABLE enrollments ADD COLUMN county VARCHAR(50);"
	$PSQL "ALTER TABLE enrollments ADD COLUMN enrollment VARCHAR(100);"
	CREATE_DATABASE_AND_TABLES_MENU "Created Table enrollments & Altered"
}

##### ##### ##### ##### #####

DELETE_DATABASE_MANAGEMENT_MENU(){
   if [[ $1 ]]
   then
      echo -e "\n$1"
   fi
   echo -e "\n~~~~~ Delete Database & Tables Menu ~~~~~"
   echo -e "\n0. Return To Database Management Menu\n1. Delete Database medicare\n2. Delete Table contracts\n3. Delete Table enrollments"
   echo "Enter Command: "
   read DATABASE_MANAGEMENT_MENU_SELECTION
   case $DATABASE_MANAGEMENT_MENU_SELECTION in
   0) DATABASE_MANAGEMENT_MENU ;;
   1) DELETE_DATABASE ;;
   2) DELETE_TABLE_CONTRACTS ;;
   3) DELETE_TABLE_ENROLLMENTS ;;
   *) DELETE_DATABASE_MANAGEMENT_MENU "Please enter a valid option." ;;
esac
}

DELETE_DATABASE(){
	$PSQL_CreateDatabase "DROP DATABASE medicare;"
}

DELETE_TABLE_MASTER(){
  $PSQL "DROP TABLE master;"
  DELETE_DATABASE_MANAGEMENT_MENU "Dropped Table master"
}

DELETE_TABLE_CONTRACTS(){
	$PSQL "DROP TABLE contracts;"
	DELETE_DATABASE_MANAGEMENT_MENU "Dropped Table contracts"
}

DELETE_TABLE_ENROLLMENTS(){
	$PSQL "DROP TABLE enrollments;"
	DELETE_DATABASE_MANAGEMENT_MENU "Dropped Table enrollments"
}

##### ##### INSERT / IMPORT ##### #####



##### ##### ##### ##### #####

SELECT_DATA_MENU(){
   if [[ $1 ]]
   then
      echo -e "\n$1"
   fi
   echo -e "\n~~~~~ Insert Data Menu ~~~~~"
   echo -e "\n0. Return To Database Management Menu\n1. Select All Bikes\n"
   echo "Enter Command: "
   read DATABASE_MANAGEMENT_MENU_SELECTION
   case $DATABASE_MANAGEMENT_MENU_SELECTION in
   0) DATABASE_MANAGEMENT_MENU ;;
   1) SELECT_ALL_BIKES ;;
   *) SELECT_DATA_MENU "Please enter a valid option." ;;
esac
}

SELECT_ALL_BIKES(){
	AVAILABLE_BIKES=$($PSQL "SELECT bike_id, type, size FROM bikes WHERE available=TRUE ORDER BY bike_id")
	echo "$AVAILABLE_BIKES"
	SELECT_DATA_MENU
}

##### ##### ##### ##### #####

UPDATE_DATA_MENU(){
   if [[ $1 ]]
   then
      echo -e "\n$1"
   fi
   echo -e "\n~~~~~ Update Bikes Available ~~~~~"
   echo -e "\n0. Return To Database Management Menu\n1. Update All Bikes as Available\n2. Update All Bikes as Unavailable\n3. Update all bikes available except BMX\n"
   echo "Enter Command: "
   read UPDATE_MENU_SELECTION
   case $UPDATE_MENU_SELECTION in
   0) DATABASE_MANAGEMENT_MENU ;;
   1) UPDATE_ALL_BIKES_AVAILABLE ;;
   2) UPDATE_ALL_BIKES_UNAVAILABLE ;;
   3) UPDATE_ALL_BIKES_AVAILABLE_EXCEPT_BMX ;;
   *) SELECT_DATA_MENU "Please enter a valid option." ;;
esac
}

UPDATE_ALL_BIKES_AVAILABLE(){
	AVAILABLE_BIKES=$($PSQL "UPDATE bikes SET AVAILABLE = true;")
	UPDATE_DATA_MENU
}

UPDATE_ALL_BIKES_AVAILABLE_EXCEPT_BMX(){
	AVAILABLE_BIKES=$($PSQL "UPDATE bikes SET available = TRUE WHERE type != 'BMX';")
	UPDATE_DATA_MENU
}

UPDATE_ALL_BIKES_UNAVAILABLE(){
	AVAILABLE_BIKES=$($PSQL "UPDATE bikes SET AVAILABLE = false;")
	UPDATE_DATA_MENU
}

##### ##### ##### ##### #####

EXIT(){
   echo -e "\nClosing Program.\n"
}

MAIN_MENU

#!/bin/bash
set -e

#create role eregistryrole;

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
CREATE ROLE wso2dbuser WITH LOGIN PASSWORD 'wso2dbpassword';
CREATE DATABASE wso2_identity_db;
CREATE DATABASE wso2_shared_db;
CREATE DATABASE wso2_citizens_db;
CREATE DATABASE wso2_employees_db;
CREATE DATABASE wso2_platform_db;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_identity_db -f /docker-entrypoint-initdb.d/sql/wso2_identity_db.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_shared_db -f /docker-entrypoint-initdb.d/sql/wso2_shared_db.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_citizens_db -f /docker-entrypoint-initdb.d/sql/wso2_shared_db.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_employees_db -f /docker-entrypoint-initdb.d/sql/wso2_shared_db.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_platform_db -f /docker-entrypoint-initdb.d/sql/wso2_shared_db.sql

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
GRANT CONNECT ON DATABASE wso2_identity_db TO wso2dbuser;
GRANT CONNECT ON DATABASE wso2_shared_db TO wso2dbuser;
GRANT CONNECT ON DATABASE wso2_citizens_db TO wso2dbuser;
GRANT CONNECT ON DATABASE wso2_employees_db TO wso2dbuser;
GRANT CONNECT ON DATABASE wso2_platform_db TO wso2dbuser;
EOSQL

#GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2iam;
#GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wso2iam;

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_identity_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

#GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2iam;
#GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wso2iam;
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_shared_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_citizens_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_employees_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_platform_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

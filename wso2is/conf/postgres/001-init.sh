#!/bin/bash
set -e

#create role eregistryrole;

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
CREATE ROLE wso2dbuser WITH LOGIN PASSWORD 'wso2dbpassword';
CREATE DATABASE wso2_identity_db;
CREATE DATABASE wso2_shared_db;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_identity_db -f /docker-entrypoint-initdb.d/sql/identity_db_identity.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_identity_db -f /docker-entrypoint-initdb.d/sql/identity_db_consent.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_shared_db -f /docker-entrypoint-initdb.d/sql/shared_db.sql

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
GRANT CONNECT ON DATABASE wso2_identity_db TO wso2dbuser;
GRANT CONNECT ON DATABASE wso2_shared_db TO wso2dbuser;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_identity_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d wso2_shared_db <<-EOSQL
GRANT USAGE ON SCHEMA public TO wso2dbuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wso2dbuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wso2dbuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wso2dbuser;
EOSQL

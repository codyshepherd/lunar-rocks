#!/bin/bash

# -e: Exit immediately if command exits with nonzero status
# -u: Treat unset variables as an error when substituting
# -x: Print commands and their arguments as they are executed
set -eux

echo "Starting postgres setup script..."

# Load psql_creds.rc file
CREDSFILE="psql_creds.rc"
set +x # hide credentials from output
source "${PWD}/${CREDSFILE}"
set -x

# Install postgres if it is not already present
if [ `dpkg-query -l | grep -q postgresql` ]; then
    echo "postgres not found. Installing..."
    sudo apt-get install --assume-yes postgresql
else
    echo "postgres is already installed. Not installing..."
fi
if [ `dpkg-query -l | grep -q postgresql-contrib` ]; then
    echo "postgres-contrib not found. Installing..."
    sudo apt-get install --assume-yes postgresql-contrib
else
    echo "postgres-contrib is already installed. Not installing..."
fi

sudo -u postgres psql -U postgres -c "CREATE DATABASE accounts;" || true
# configure Postgres schema and local dev account permissions
sudo -u postgres psql -U postgres -d accounts -c "CREATE SCHEMA registered_accounts;" || true
set +x
sudo -u postgres psql -U postgres -d accounts -c "CREATE USER ${PSQLUSER} with PASSWORD '${PSQLPW}';" || true
set -x
echo "Created user account ${PSQLUSER} for registered_accounts schema"
sudo -u postgres psql -U postgres -d accounts -c "CREATE TABLE registered_accounts.registered 
(id varchar(255) PRIMARY KEY,
username varchar(255) UNIQUE NOT NULL,
email varchar(255) NOT NULL,
passHash varchar(255) NOT NULL
);" || true
sudo -u postgres psql -U postgres -d accounts -c "CREATE TABLE registered_accounts.tokens 
(token varchar(255) PRIMARY KEY,
type integer NOT NULL,
valid boolean NOT NULL,
expires TIMESTAMP WITH TIME ZONE NOT NULL,
userid varchar(255) REFERENCES registered_accounts.registered(id)
);" || true
sudo -u postgres psql -U postgres -d accounts -c "GRANT ALL ON DATABASE accounts TO ${PSQLUSER};"
sudo -u postgres psql -U postgres -d accounts -c "GRANT ALL ON SCHEMA registered_accounts TO ${PSQLUSER};"
sudo -u postgres psql -U postgres -d accounts -c "GRANT ALL ON ALL TABLES IN SCHEMA registered_accounts TO ${PSQLUSER};"

echo "postgres setup complete!"

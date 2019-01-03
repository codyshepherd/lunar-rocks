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

# configure Postgres schema and local dev account permissions
sudo -u postgres psql -U postgres -c "CREATE SCHEMA Accounts;" || true
set +x
sudo -u postgres psql -U postgres -c "CREATE USER ${PSQLUSER} with PASSWORD '${PSQLPW}';"
set -x
echo "Created user account ${PSQLUSER} for Account schema"
sudo -u postgres psql -U postgres -c "GRANT ALL ON SCHEMA Accounts TO ${PSQLUSER};"
sudo -u postgres psql -U postgres -c "GRANT ALL ON ALL TABLES IN SCHEMA Accounts TO ${PSQLUSER};"

echo "postgres setup complete!"

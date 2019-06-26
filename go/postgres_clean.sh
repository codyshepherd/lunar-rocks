#!/bin/bash

# -e: Exit immediately if command exits with nonzero status
# -u: Treat unset variables as an error when substituting
# -x: Print commands and their arguments as they are executed
set -eux

# Load psql_creds.rc file
CREDSFILE="psql_creds.rc"
set +x # hide credentials from output
source "${PWD}/${CREDSFILE}"
set -x

sudo -u postgres psql -U postgres -d accounts -c "DELETE FROM registered_accounts.tokens;" || true
sudo -u postgres psql -U postgres -d accounts -c "DELETE FROM registered_accounts.registered;" || true
# uncomment the following to drop tables (in the event of table change)
#sudo -u postgres psql -U postgres -d accounts -c "Drop table registered_accounts.tokens;" || true
#sudo -u postgres psql -U postgres -d accounts -c "Drop table registered_accounts.registered;" || true

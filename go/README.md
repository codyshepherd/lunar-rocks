# Golang Backend Services Readme

The Lunar Rocks backend is comprised of several independent services. See the
individual per-service sections in this document for brief discussions of
those, and find more detailed READMEs in the subdirectory for each service.

==================================================

## Direnv

Direnv acts like a virtualenv for go development, and will help keep your local
dev environment tidy. It will also allow the various services to find files
where expected when testing locally.

Documentation of Direnv can be found at: https://direnv.net

### To install direnv, run the following commands. Note that you can select
a different directory to add to the GOPATH (other than $HOME/go) if you wish
(though this is "unsupported" by me and may not be a simple substitution in
these instructions):

```
export GOPATH=${GOPATH:-$HOME/go}
mkdir -p $GOPATH/src/github.com/direnv
git clone https://github.com/direnv/direnv.git $GOPATH/src/github.com/direnv/direnv
cd $GOPATH/src/github.com/direnv/direnv
make install
```

To hook direnv into bash, add the following line at the end of ~/.bashrc:

`eval "$(direnv hook bash)"`

Your project folder (in this case `lunar-rocks/go/` should have a file called
`.envrc` exporting environment variables such as $GOPATH. The easiest way to
achieve this is to place Direnv's `layout` command in the `.envrc` file, which
will allow it to automatically map your directory and environment structure:

`echo 'layout go' > .envrc`

Once this is done, you will need to perform a one-time authorization of direnv
to access your filesystem by running:

`direnv allow .` or `direnv allow .envrc`

This should conclude the setup process for direnv.

==================================================

## Services

---

### Webserver

__Basic Compilation and Runtime__

Note the the following method only works well if your direnv is set up. If
you find that the `go` build commands give you errors, re-check that you have
a `.envrc` file in your `go` directory and that you have run `direnv allow`.

To download dependencies, compile the server, and run it, navigate to the `go`
directory and enter:

```
go get webserver
sudo ./bin/webserver
```

__Or__

If you already have all the dependencies, you can build to the local dir with:

```
go build webserver
sudo ./webserver
```

__Note__

The webserver supports the following command-line options (./webserver --help
to learn a bit more):

`-log={n, q, v, vvv}`: set log level
`-port=#`: set the port for the server to listen on

__Finally__

Navigate to `localhost:1025/` in your favorite browser

---

### Accounts

__Local Development: Install Postgres:__

Create a file in `lunar-rocks/go/` directory called `psql_creds.rc`. This file
should contain two lines:

```
PSQLUSER=xxx
PSQLPW=yyy
```

Where `xxx` is your desired local-dev username, and `yyy` is your desired local
dev password.

Next, run the `postgres_setup.sh` script, which will prompt you for your sudo
password and install the required apt packages.

This script should also import your devel credentials and set up a postgresql user
with them, as well as create an Accounts schema in the default database and
give your user permissions to create and alter tables in that schema.

__Note:__

You may want to also create a `.pgpass` file in your home directory with the
following line:

`localhost:*:postgres:psqluser:psqlpw`

This will enable you to log into an interactive postgres prompt with your devel
credentials for debugging or testing, though this can be avoided using the
`-W` switch when running `psql` to force a password prompt.

==================================================

TODO

compile & run script?

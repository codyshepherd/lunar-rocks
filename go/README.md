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
a different directory to add to the GOPATH (other than $HOME/go) if you wish:

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

The webserver requires certificates to serve HTTPS. For local development and
testing, these will be self-signed certificates that must live in
`lunar-rocks/go/` (the directory where this README lives). Instructions on
how to generate these certificates can be found in
`lunar-rocks/go/src/webserver/README.md`.

__Basic Compilation and Runtime__

To download dependencies and compile the server, navigate to the `go` directory and enter:

go get webserver

To run, from `go` directory:

sudo ./bin/webserver

Then navigate to `localhost:443` in your favorite browser

---

### Accounts

TODO

==================================================

TODO

compile & run script?

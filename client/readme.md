# Elm Frontend Readme

The Lunar Rocks frontend is an Elm 0.19 application.

==================================================

## Setup

Install [Elm](https://guide.elm-lang.org/install.html),
[elm-live](https://github.com/wking-io/elm-live), and
[uglify-js](https://www.npmjs.com/package/uglify-js) globally.

```
npm install -g elm elm-live uglify-js

```

Install npm packages in the `client` directory.
```
npm install
```

## Develop 

This script uses `elm-live` to compile and serve the client. 

```
./develop.sh
```

`elm-live` compiles and reloads the application when changes to static or Elm files are made.

This script is useful when working on the client, but note that the Lunar Rocks
webserver will not see changes to the client without running one of the build
scripts below.


## Build

Both build scripts emit the compiled application to the `build` directory for consumption
by the webserver.

Compile a development build without optimization.

```
./compile.sh
```

Compile an optimized production build.

```
./optimize.sh
```

Note that all debug statements must be removed for the optimized build.

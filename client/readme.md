# Elm Frontend Readme

The Lunar Rocks frontend is an Elm 0.19 application.

==================================================

## Setup

Install npm packages from the `client` directory.
```
npm install
```

Install [Elm](https://guide.elm-lang.org/install.html) and [elm-Live](https://github.com/wking-io/elm-live), and [uglify-js](https://www.npmjs.com/package/uglify-js).

## Develop 

Start the elm app from the `client` directory.

```
bash develop.sh
```

## Build

Compile the client without optimization.
```
bash compile.sh
```

Compile an optimized production build.

```
bash optimize.sh
```

Note that all debug statements must be removed for the optimized build.

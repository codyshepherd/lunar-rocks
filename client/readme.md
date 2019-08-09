# Elm Frontend Readme

The Lunar Rocks frontend is an Elm 0.19 application.

==================================================

## Setup

Install [Elm](https://guide.elm-lang.org/install.html) and
[parcel](https://github.com/wking-io/elm-live)

```
npm install -g elm parcel-bundler

```

Install npm packages in the `client` directory.
```
npm install
```

## Develop 

`parcel` provides a local webserver and hot reloading which are useful during
local development.

```
parcel src/index.html
```

## Build

Both `parcel` build commands emit compiled artifacts to the `dist` directory for
consumption by the Lunar Rocks webserver.

Compile a development build without optimization.

```
parcel build src/index.html --no-minify
```

Compile an optimized production build.

```
parcel build src/index.html
```

All debug statements must be removed for the optimized build.

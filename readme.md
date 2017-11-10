# Music

Cody Shepherd
Brian Ginsburg

## Build

Compile the server with `sbt` from the project root.
```
sbt compile
```

Compile the client from the `elm` directory.
```
elm-make src/Main.elm --output=main.js
```

## Run

Start the server with `sbt run` in the project root. Open `index.html` in a
browser.

#!/bin/sh                                                                       

set -e

src="src/Main.elm"
js="build/elm.js"
min="build/elm.min.js"

elm make --output=$js $src

echo "Compiled size: $(cat $js | wc -c) bytes  ($js)"

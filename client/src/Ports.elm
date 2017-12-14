port module Ports exposing (..)

import Models exposing (Note, Score)


port sendScore : Score -> Cmd msg

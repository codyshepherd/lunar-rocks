port module Ports exposing (..)

import Models exposing (Note)


port play : Note -> Cmd msg

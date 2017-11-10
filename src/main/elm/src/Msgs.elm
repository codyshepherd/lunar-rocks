module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (Cell, SessionId)
import Time exposing (Time)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | UpdateBoard Cell
    | UserInput String
    | Send
    | Tick Time
    | IncomingMessage String

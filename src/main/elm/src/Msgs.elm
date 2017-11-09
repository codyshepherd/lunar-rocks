module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (Cell, SessionId)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | UpdateBoard Cell
    | UserInput String
    | Send
    | IncomingMessage String

module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (SessionId)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | UpdateBoard ( Int, Int )
    | UserInput String
    | Send
    | IncomingMessage String

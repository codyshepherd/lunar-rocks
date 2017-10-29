module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (SessionId)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | Input String
    | Send
    | IncomingMessage String

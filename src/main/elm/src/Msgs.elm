module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (Cell, ClientId, SessionId, TrackId)
import Time exposing (Time)
import Window exposing (Size)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | UpdateBoard Cell
    | UserInput String
    | Send
    | Tick Time
    | IncomingMessage String
    | WindowResize Size
    | SelectName
    | RequestTrack TrackId ClientId
    | ReleaseTrack TrackId ClientId

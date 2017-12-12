module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (Cell, ClientId, SessionId, Track, TrackId)
import Time exposing (Time)
import Window exposing (Size)


type Msg
    = AddSession
    | Broadcast (List SessionId) Track
    | Disconnect
    | IncomingMessage String
    | LeaveSession SessionId
    | OnLocationChange Location
    | ReleaseTrack SessionId TrackId ClientId
    | RequestTrack SessionId TrackId ClientId
    | SelectName
    | Send SessionId
    | Tick Time
    | ToggleSessionButton SessionId
    | UpdateBoard Cell
    | UserInput String
    | WindowResize Size

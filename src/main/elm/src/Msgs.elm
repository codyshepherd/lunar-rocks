module Msgs exposing (..)

import Navigation exposing (Location)
import Models exposing (Cell, ClientId, SessionId, Track, TrackId)
import Time exposing (Time)
import Window exposing (Size)


type Msg
    = OnLocationChange Location
    | AddSession SessionId
    | UpdateBoard Cell
    | UserInput String
    | Tick Time
    | IncomingMessage String
    | WindowResize Size
    | SelectName
    | RequestTrack SessionId TrackId ClientId
    | ReleaseTrack SessionId TrackId ClientId
    | ToggleSessionButton SessionId
    | Broadcast (List SessionId) Track

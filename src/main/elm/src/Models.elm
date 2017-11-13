module Models exposing (..)

import Window exposing (Size)


type alias Model =
    { clientId : ClientId
    , username : String
    , trackId : TrackId
    , serverId : ServerId
    , session : Session
    , sessions : Sessions
    , route : Route
    , score : Score
    , windowSize : Size
    }


type alias ClientId =
    -- TODO: will be UUID
    Int


type alias ServerId =
    Int



-- SESSION


type alias SessionId =
    Int


type alias Sessions =
    { sessions : List SessionId
    , clientSessions : List SessionId
    , selectedSessions : List SessionId
    }


type alias Session =
    { id : SessionId
    , beats : Int
    , tones : Int
    , clock : Int
    , tempo : Int
    , clients : List ClientId
    , board : Board
    , input : String
    , messages : List String
    }



-- BOARD


type alias Board =
    List Track


type alias TrackId =
    Int


type alias Track =
    { trackId : TrackId
    , clientId : ClientId
    , username : String
    , instrument : String
    , grid : List (List Int)
    }


type alias Cell =
    { trackId : TrackId
    , column : Int
    , row : Int
    , action : Int
    }



-- AUDIO


type alias Score =
    List Note


type alias Note =
    { trackId : TrackId
    , beat : Int
    , duration : Int
    , tone : Int
    }



-- ROUTING


type Route
    = Home
    | SessionRoute SessionId
    | NotFoundRoute



-- INIT


initialModel : Route -> Model
initialModel route =
    { clientId = 1
    , username = ""
    , trackId = 0
    , serverId = 0
    , session =
        Session 0
            8
            13
            1
            120
            []
            [ Track 0 0 "" "Synth" (List.repeat 13 (List.repeat 8 0))
            , Track 1 0 "" "Drums" (List.repeat 13 (List.repeat 8 0))
            ]
            ""
            []
    , sessions =
        { sessions = [ 1, 2, 3 ]
        , clientSessions = []
        , selectedSessions = []
        }
    , route = route
    , score = []
    , windowSize = { width = 0, height = 0 }
    }

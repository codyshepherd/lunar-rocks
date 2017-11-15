module Models exposing (..)

import Window exposing (Size)


type alias Model =
    { clientId : ClientId
    , username : String
    , trackId : TrackId
    , serverId : ServerId
    , session : Session -- TODO: make a list of Session
    , sessions : Sessions -- TODO: SessionLists
    , route : Route
    , score : Score
    , windowSize : Size
    }


type alias ClientId =
    String


type alias ServerId =
    Int



-- SESSION


type alias SessionId =
    Int


type alias Sessions =
    -- TODO: rename this as SessionLists
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
    , rowLabels : List String
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
    { clientId = "clown shoes"
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
            [ Track 0
                ""
                ""
                "Synth"
                (List.repeat 13 (List.repeat 8 0))
                [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
            , Track 1
                ""
                ""
                "Drums"
                (List.repeat 13 (List.repeat 8 0))
                [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
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

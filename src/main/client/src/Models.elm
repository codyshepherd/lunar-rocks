module Models exposing (..)

import Window exposing (Size)


type alias Model =
    { clientId : ClientId
    , username : String
    , serverId : ServerId
    , sessionId : SessionId
    , trackId : TrackId
    , sessions : List Session
    , sessionLists : SessionLists
    , route : Route
    , input : String
    , windowSize : Size
    , serverMessage : String
    , validationErrors : List ValidationError
    }


type alias ClientId =
    String


type alias ServerId =
    Int


type Field
    = Name


type alias ValidationError =
    ( Field, String )



-- SESSION


type alias SessionId =
    Int


type alias SessionLists =
    { allSessions : List SessionId
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
    , score : Score
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
    { sessionId : SessionId
    , trackId : TrackId
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


websocketServer : String
websocketServer =
    "ws://localhost:8795"


initialModel : Route -> Model
initialModel route =
    { clientId = "clown shoes"
    , username = ""
    , serverId = 0
    , sessionId = 0
    , trackId = 0
    , sessions =
        [ emptySession 0 ]
    , sessionLists =
        { allSessions = [ 0 ]
        , clientSessions = []
        , selectedSessions = []
        }
    , route = route
    , input = ""
    , windowSize = { width = 0, height = 0 }
    , serverMessage = ""
    , validationErrors = []
    }


emptySession : Int -> Session
emptySession id =
    Session id
        8
        13
        1
        120
        []
        [ Track 0
            ""
            ""
            "Xylophone"
            (List.repeat 13 (List.repeat 8 0))
            [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
        , Track 1
            ""
            ""
            "Marimba"
            (List.repeat 13 (List.repeat 8 0))
            [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
        ]
        []
        []

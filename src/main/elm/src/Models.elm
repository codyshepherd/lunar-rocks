module Models exposing (..)


type alias Model =
    { clientId : ClientId
    , serverId : ServerId
    , session : Session
    , sessions : List SessionId
    , route : Route
    , score : Score
    }


initialModel : Route -> Model
initialModel route =
    { clientId = 0
    , serverId = 0
    , session =
        Session ""
            8
            13
            1
            120
            []
            [ Track 0 0 (List.repeat 13 (List.repeat 8 0))
            , Track 1 1 (List.repeat 13 (List.repeat 8 0))
            ]
            ""
            []
    , sessions = [ "1", "2", "3" ]
    , route = route
    , score = []
    }


type Route
    = Home
    | SessionRoute SessionId
    | NotFoundRoute


type alias SessionId =
    -- change to Int
    String


type alias ClientId =
    Int


type alias ServerId =
    Int


type alias Board =
    List Track


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


type alias TrackId =
    Int


type alias Track =
    { trackId : TrackId
    , clientId : ClientId
    , grid : List (List Int)
    }


type alias Cell =
    { trackId : TrackId
    , column : Int
    , row : Int
    , action : Int
    }


type alias Score =
    List Note


type alias Note =
    { trackId : TrackId
    , beat : Int
    , duration : Int
    , tone : Int
    }


type Styles
    = None
    | Main
    | Navigation
    | Container
    | PlayBlue
    | PlayRed
    | Rest
    | MessageInput

module Models exposing (..)


type alias Model =
    { clientId : ClientId
    , serverId : ServerId
    , session : Session
    , sessions : List SessionId
    , route : Route
    }


initialModel : Route -> Model
initialModel route =
    { clientId = ""
    , serverId = ""
    , session =
        Session ""
            0
            []
            [ Track
                0
                ""
                [ [ 1, 0, 0, 0, 1, 0, 0, 0 ]
                , List.repeat 8 1
                , List.repeat 8 0
                , List.repeat 8 0
                , List.repeat 8 0
                , [ 0, 1, 0, 1, 0, 1, 0, 1 ]
                , List.repeat 8 0
                , List.repeat 8 0
                , [ 0, 1, 0, 1, 0, 1, 0, 1 ]
                , [ 1, 0, 0, 0, 1, 0, 0, 0 ]
                , [ 1, 0, 1, 0, 1, 0, 1, 0 ]
                , List.repeat 8 0
                , [ 1, 0, 1, 0, 1, 0, 1, 0 ]
                ]
            ]
            ""
            []
    , sessions = [ "1", "2", "3" ]
    , route = route
    }


type Route
    = Home
    | SessionRoute SessionId
    | NotFoundRoute


type alias SessionId =
    String


type alias ClientId =
    String


type alias ServerId =
    String


type alias Session =
    { id : SessionId
    , tempo : Int
    , clients : List ClientId
    , board : List Track
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


type Styles
    = None
    | Main
    | Navigation
    | Container
    | Play
    | Rest
    | MessageInput

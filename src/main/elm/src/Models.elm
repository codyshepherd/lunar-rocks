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
    , session = Session "" 0 [] [] "" []
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
    String


type alias Track =
    { trackID : TrackId
    , clientID : ClientId
    , grid : List (List Int)
    }

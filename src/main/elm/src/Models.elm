module Models exposing (..)


type alias Model =
    { session : Session
    , sessions : List SessionId
    , route : Route
    }


initialModel : Route -> Model
initialModel route =
    { session = Session "" "" []
    , sessions = [ "1", "2", "3" ]
    , route = route
    }


type alias SessionId =
    String


type alias Session =
    { id : SessionId
    , input : String
    , messages : List String
    }


type Route
    = Home
    | SessionRoute SessionId
    | NotFoundRoute


type Styles
    = None
    | Main
    | Navigation
    | MessageInput

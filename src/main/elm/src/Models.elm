module Models exposing (..)

import Window exposing (Size)


type alias Model =
    { clientId : ClientId
    , username : String
    , trackId : TrackId
    , serverId : ServerId
    , session : Session
    , sessions : List SessionId
    , route : Route
    , score : Score
    , windowSize : Size
    }


initialModel : Route -> Model
initialModel route =
    { clientId = 0
    , username = ""
    , trackId = 0
    , serverId = 0
    , session =
        Session ""
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
    , sessions = [ "1", "2", "3" ]
    , route = route
    , score = []
    , windowSize = { width = 0, height = 0 }
    }


type Route
    = Home
    | SessionRoute SessionId
    | NotFoundRoute


type alias SessionId =
    -- TODO: change to Int
    String


type alias ClientId =
    -- TODO: will be UUID
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
    | InstrumentLabel
    | Text
    | Navigation
    | Heading
    | SubHeading
    | GridBlock
    | PlayPurple
    | PlayOrange
    | Rest
    | MessageInput
    | SessionListing

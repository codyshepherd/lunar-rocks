module Models exposing (..)

import Element.Input as Input exposing (SelectMsg, SelectWith, autocomplete)
import Navigation exposing (Location)
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
    , selectedCell : Cell
    , windowSize : Size
    , selectInstrumentZero : Input.SelectWith Instrument Msg
    , selectInstrumentOne : Input.SelectWith Instrument Msg
    , serverMessage : String
    , validationErrors : List ValidationError
    }


type alias ClientId =
    String


type alias ServerId =
    Int



-- MESSAGES


type Msg
    = AddSession
    | Broadcast (List SessionId) Track
    | Disconnect
    | IncomingMessage String
    | LeaveSession SessionId
    | OnLocationChange Location
    | ReleaseTrack SessionId TrackId ClientId
    | RequestTrack SessionId TrackId ClientId
    | SelectInstrumentZero (Input.SelectMsg Instrument)
    | SelectInstrumentOne (Input.SelectMsg Instrument)
    | SelectCell Cell
    | SelectName
    | SendSession SessionId
    | ToggleSessionButton SessionId
    | UpdateGrid Cell
    | UserInput String
    | WindowResize Size



-- VALIDATION


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


type alias Track =
    { trackId : TrackId
    , clientId : ClientId
    , username : String
    , instrument : String
    , grid : List (List Int)
    , rowLabels : List String
    }


type alias TrackId =
    Int


type UpdateCellAction
    = Add
    | Remove


type alias Cell =
    { sessionId : SessionId
    , trackId : TrackId
    , column : Int
    , row : Int
    , length : Int
    , action : Int
    }


type Instrument
    = Guitar ( SessionId, TrackId )
    | Piano ( SessionId, TrackId )
    | Marimba ( SessionId, TrackId )
    | Xylophone ( SessionId, TrackId )


type alias InstrumentSelects =
    ( Input.SelectWith Instrument Msg, Input.SelectWith Instrument Msg )



-- AUDIO


type alias Score =
    List Note


type alias Note =
    { trackId : TrackId
    , instrument : String
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
    , selectInstrumentZero = Input.dropMenu Nothing SelectInstrumentZero
    , selectInstrumentOne = Input.dropMenu Nothing SelectInstrumentOne
    , selectedCell = emptyCell
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
            "Guitar"
            (List.repeat 13 (List.repeat 8 0))
            [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
        , Track 1
            ""
            ""
            "Piano"
            (List.repeat 13 (List.repeat 8 0))
            [ "C", "B", "A♯", "A", "G♯", "G", "F♯", "F", "E", "D♯", "D", "C♯", "C" ]
        ]
        []
        []


emptyCell : Cell
emptyCell =
    { sessionId = 0
    , trackId = 0
    , row = 0
    , column = 0
    , length = 0
    , action = 0
    }

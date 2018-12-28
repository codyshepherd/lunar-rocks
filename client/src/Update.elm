module Update exposing (..)

import Decode exposing (..)
import Encode exposing (..)
import Element.Input as Input exposing (updateSelection)
import Json.Encode exposing (encode, Value, string, int, float, bool, list, object)
import Json.Decode exposing (decodeString)
import List.Extra exposing ((!!))
import Models exposing (..)
import Ports exposing (sendScore)
import Routing exposing (parseLocation)
import ServerUpdate exposing (serverUpdateModel, serverCommand)
import Score exposing (readGrid)
import Validate exposing (ifBlank, ifInvalid)
import WebSocket


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddSession ->
            ( model
            , WebSocket.send websocketServer (encodeMessage model.clientId 101 (object []))
            )

        Broadcast selectedSessions track ->
            ( model
            , WebSocket.send websocketServer
                (encodeMessage model.clientId 108 (encodeBroadcast selectedSessions (encodeTrack track)))
            )

        Disconnect ->
            ( model
            , WebSocket.send websocketServer (encodeMessage model.clientId 106 (object []))
            )

        IncomingMessage rawMessage ->
            let
                serverMessage =
                    case Debug.log "serverMessage" (Json.Decode.decodeString decodeServerMessage rawMessage) of
                        -- case (Json.Decode.decodeString decodeServerMessage rawMessage) of
                        Ok m ->
                            Just m

                        Err error ->
                            Nothing

                newModel =
                    serverUpdateModel serverMessage model

                command =
                    serverCommand serverMessage newModel
            in
                ( newModel, command )

        LeaveSession sessionId ->
            let
                newSessions =
                    List.filter (\s -> s.id /= sessionId) model.sessions

                sessionLists =
                    model.sessionLists

                newClientSessions =
                    List.filter (\id -> id /= sessionId) sessionLists.clientSessions

                newSessionLists =
                    { sessionLists | clientSessions = newClientSessions }
            in
                ( { model | sessions = newSessions, sessionLists = newSessionLists }
                , WebSocket.send websocketServer
                    (encodeMessage model.clientId 104 (encodeSessionId sessionId))
                )

        OnLocationChange location ->
            let
                newRoute =
                    parseLocation location

                sessions =
                    model.sessions

                session =
                    case newRoute of
                        SessionRoute id ->
                            Maybe.withDefault
                                (emptySession id)
                                (List.head (List.filter (\s -> s.id == id) sessions))

                        Home ->
                            emptySession 0

                        NotFoundRoute ->
                            emptySession 0

                newSessions =
                    session :: (List.filter (\s -> s.id /= session.id) sessions)

                newSessionId =
                    case newRoute of
                        SessionRoute id ->
                            id

                        Home ->
                            0

                        NotFoundRoute ->
                            0

                sessionLists =
                    model.sessionLists

                newSessionLists =
                    { sessionLists | selectedSessions = [] }

                command =
                    case newRoute of
                        SessionRoute id ->
                            WebSocket.send websocketServer
                                (encodeMessage model.clientId 103 (encodeSessionId id))

                        Home ->
                            sendScore session.score

                        NotFoundRoute ->
                            WebSocket.send websocketServer
                                (encodeMessage model.clientId 114 (encodeError "Route not found"))
            in
                ( { model
                    | route = newRoute
                    , sessionId = newSessionId
                    , sessions = newSessions
                    , sessionLists = newSessionLists
                  }
                , command
                )

        ReleaseTrack sessionId trackId clientId ->
            let
                session =
                    Maybe.withDefault
                        (emptySession sessionId)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                newTrack =
                    updateTrackUser trackId "" "" session.board

                newBoard =
                    List.take trackId session.board
                        ++ newTrack
                        :: List.drop (trackId + 1) session.board

                newSession =
                    { session | board = newBoard }

                newSessions =
                    newSession :: model.sessions

                sessionLists =
                    model.sessionLists

                newClientSessions =
                    case List.filter (\t -> t.clientId == model.clientId) newBoard of
                        [] ->
                            List.filter (\cs -> cs /= session.id) sessionLists.clientSessions

                        _ ->
                            sessionLists.clientSessions

                newSelectedSessions =
                    List.filter (\cs -> cs /= session.id) sessionLists.selectedSessions

                newSessionLists =
                    { sessionLists | clientSessions = newClientSessions, selectedSessions = newSelectedSessions }
            in
                ( { model | sessions = newSessions, sessionLists = newSessionLists }
                , WebSocket.send websocketServer
                    (encodeMessage model.clientId 110 (encodeTrackRequest sessionId trackId))
                )

        RequestTrack sessionId trackId clientId ->
            ( model
            , WebSocket.send websocketServer
                (encodeMessage model.clientId 109 (encodeTrackRequest sessionId trackId))
            )

        SelectInstrumentZero selectMsg ->
            let
                select =
                    Input.updateSelection selectMsg model.selectInstrumentZero

                ( newSessions, command ) =
                    selectInstrument select model
            in
                ( { model | sessions = newSessions, selectInstrumentZero = select }, command )

        SelectInstrumentOne selectMsg ->
            let
                select =
                    Input.updateSelection selectMsg model.selectInstrumentOne

                ( newSessions, command ) =
                    selectInstrument select model
            in
                ( { model | sessions = newSessions, selectInstrumentOne = select }, command )

        SelectCell cell ->
            ( { model | selectedCell = cell }, Cmd.none )

        SelectName ->
            case validate model of
                [] ->
                    let
                        input =
                            model.input

                        message =
                            encodeMessage model.clientId 112 (encodeNickname input)
                    in
                        ( { model | username = input, validationErrors = [] }
                        , WebSocket.send websocketServer message
                        )

                errors ->
                    ( { model | validationErrors = errors }, Cmd.none )

        SendSession sessionId ->
            let
                session =
                    Maybe.withDefault
                        (emptySession 0)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))
            in
                ( model
                , WebSocket.send websocketServer
                    (encodeMessage model.clientId 100 (encodeSession session))
                )

        ToggleSessionButton sessionId ->
            let
                sessionLists =
                    model.sessionLists

                selectedSessions =
                    sessionLists.selectedSessions

                newSelectedSessions =
                    case List.member sessionId selectedSessions of
                        True ->
                            List.filter (\s -> s /= sessionId) selectedSessions

                        False ->
                            List.sort (sessionId :: selectedSessions)

                newSessionLists =
                    { sessionLists | selectedSessions = newSelectedSessions }
            in
                ( { model | sessionLists = newSessionLists }, Cmd.none )

        UpdateGrid cell ->
            let
                newSession =
                    updateSession cell model

                newSessions =
                    newSession :: (List.filter (\s -> s.id /= cell.sessionId) model.sessions)
            in
                ( { model | sessions = newSessions, selectedCell = emptyCell }, sendScore newSession.score )

        UserInput newInput ->
            ( { model | input = newInput }, Cmd.none )

        WindowResize size ->
            ( { model | windowSize = size }, Cmd.none )



-- VALIDATORS


validate : Model -> List ValidationError
validate =
    Validate.all
        [ .input >> ifBlank ( Name, "🗙 Nickname can't be blank." )
        , .input
            >> ifInvalid
                (\n -> String.length n > 20)
                ( Name, "🗙 Nickname must be shorter than 20 characters." )
        , .input
            >> ifInvalid
                (\n -> String.length n < 3)
                ( Name, "🗙 Nickname must be at least 3 characters long." )
        ]



-- SESSION


updateSession : Cell -> Model -> Session
updateSession cell model =
    let
        session =
            Maybe.withDefault
                (emptySession cell.sessionId)
                (List.head (List.filter (\s -> s.id == cell.sessionId) model.sessions))

        newBoard =
            (updateBoard session.board cell model.selectedCell)

        newScore =
            List.concatMap
                (\track -> readGrid track.grid track.trackId track.instrument session.tones)
                newBoard
    in
        { session
            | board = newBoard
            , score = newScore
        }


updateBoard : Board -> Cell -> Cell -> Board
updateBoard board cell selected =
    List.take cell.trackId board
        ++ (updateTrack (board !! cell.trackId) cell selected)
        :: List.drop (cell.trackId + 1) board


updateTrack : Maybe Track -> Cell -> Cell -> Track
updateTrack track cell selected =
    case track of
        Just t ->
            { t | grid = updateGrid t cell selected }

        Nothing ->
            Track -1 "" "" "404s" [] []


updateGrid : Track -> Cell -> Cell -> List (List Int)
updateGrid track cell selected =
    if
        (cell.column >= selected.column)
            && (cell.row > (selected.row - 2))
            && (cell.row < (selected.row + 2))
    then
        if cell.column == selected.column && cell.action /= 0 then
            updateRow track.grid Remove cell cell.length
        else
            updateRow track.grid Add selected ((cell.column + cell.length) - selected.column)
    else
        track.grid


updateRow : List (List Int) -> UpdateCellAction -> Cell -> Int -> List (List Int)
updateRow grid updateAction cell length =
    let
        row =
            case grid !! cell.row of
                Just r ->
                    r

                Nothing ->
                    []

        newRow =
            List.take cell.column row
                ++ case updateAction of
                    Add ->
                        List.range 1 length
                            ++ List.drop (cell.column + length) row

                    Remove ->
                        List.repeat length 0
                            ++ List.drop (cell.column + length) row
    in
        List.take cell.row grid
            ++ newRow
            :: List.drop (cell.row + 1) grid


updateTrackUser : TrackId -> ClientId -> String -> Board -> Track
updateTrackUser trackId clientId username board =
    let
        track =
            List.head (List.filter (\t -> t.trackId == trackId) board)
    in
        case track of
            Just t ->
                { t | clientId = clientId, username = username }

            Nothing ->
                Track -1 "" "" "404s" [] []



-- SELECT_INSTRUMENT


selectInstrument select model =
    case Input.selected select of
        Just instr ->
            let
                instrumentSelection =
                    case instr of
                        Guitar ( sessionId, trackId ) ->
                            { instrument = "Guitar", sessionId = sessionId, trackId = trackId }

                        Piano ( sessionId, trackId ) ->
                            { instrument = "Piano", sessionId = sessionId, trackId = trackId }

                        Marimba ( sessionId, trackId ) ->
                            { instrument = "Marimba", sessionId = sessionId, trackId = trackId }

                        Xylophone ( sessionId, trackId ) ->
                            { instrument = "Xylophone", sessionId = sessionId, trackId = trackId }

                session =
                    Maybe.withDefault
                        (emptySession instrumentSelection.sessionId)
                        (List.head (List.filter (\s -> s.id == instrumentSelection.sessionId) model.sessions))

                newSession =
                    updateInstrument instrumentSelection select session
            in
                ( newSession :: List.filter (\s -> s.id /= instrumentSelection.sessionId) model.sessions
                , sendScore newSession.score
                )

        Nothing ->
            ( model.sessions, Cmd.none )


updateInstrument instrumentSelection searchInstrument session =
    case Input.selected searchInstrument of
        Nothing ->
            session

        Just _ ->
            let
                newTrack =
                    updateTrackInstrument instrumentSelection.trackId instrumentSelection.instrument session.board

                newBoard =
                    List.take instrumentSelection.trackId session.board
                        ++ newTrack
                        :: List.drop (instrumentSelection.trackId + 1) session.board

                newScore =
                    List.concatMap
                        (\track -> readGrid track.grid track.trackId track.instrument session.tones)
                        newBoard
            in
                { session | board = newBoard, score = newScore }


updateTrackInstrument : TrackId -> String -> Board -> Track
updateTrackInstrument trackId instrument board =
    let
        track =
            List.head (List.filter (\t -> t.trackId == trackId) board)
    in
        case track of
            Just t ->
                { t
                    | instrument = instrument
                }

            Nothing ->
                Track -1 "" "" "404s" [] []

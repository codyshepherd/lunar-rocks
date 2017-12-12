module Update exposing (..)

import Decode exposing (..)
import Encode exposing (..)
import Json.Encode exposing (encode, Value, string, int, float, bool, list, object)
import Json.Decode exposing (decodeString)
import List.Extra exposing ((!!))
import Models exposing (..)
import Msgs exposing (..)
import Ports exposing (play)
import Routing exposing (parseLocation)
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
                    -- case Debug.log "serverMessage" (Json.Decode.decodeString decodeServerMessage rawMessage) of
                    case (Json.Decode.decodeString decodeServerMessage rawMessage) of
                        Ok m ->
                            Just m

                        Err error ->
                            Nothing

                newModel =
                    serverUpdateModel serverMessage model
            in
                ( newModel, Cmd.none )

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

                websocketMessage =
                    case newRoute of
                        SessionRoute id ->
                            WebSocket.send websocketServer
                                (encodeMessage model.clientId 103 (encodeSessionId id))

                        Home ->
                            Cmd.none

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
                , websocketMessage
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

        Send sessionId ->
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

        Tick time ->
            let
                sessionId =
                    model.sessionId

                session =
                    Maybe.withDefault
                        (emptySession sessionId)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                newSession =
                    { session
                        | clock = increment session.clock session.beats
                    }

                newSessions =
                    newSession :: model.sessions
            in
                { model
                    | sessions = newSessions
                }
                    ! [ Cmd.batch (playNotes newSession.clock session.score) ]

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

        UpdateBoard cell ->
            let
                newSessions =
                    updateSessions cell model
            in
                ( { model | sessions = newSessions }, Cmd.none )

        UserInput newInput ->
            ( { model | input = newInput }, Cmd.none )

        WindowResize size ->
            ( { model | windowSize = size }, Cmd.none )



-- VALIDATORS


validate : Model -> List ValidationError
validate =
    Validate.all
        [ .input >> ifBlank ( Name, "Nickname can't be blank." )
        , .input
            >> ifInvalid
                (\n -> String.length n >= 20)
                ( Name, "Nickname must be less than 20 characters." )
        ]



-- SESSION


updateSessions : Cell -> Model -> List Session
updateSessions cell model =
    let
        session =
            Maybe.withDefault
                (emptySession cell.sessionId)
                (List.head (List.filter (\s -> s.id == cell.sessionId) model.sessions))

        newScore =
            case cell.action of
                0 ->
                    (removeNote cell session.score)

                _ ->
                    let
                        note =
                            Note
                                cell.trackId
                                (cell.column + 1)
                                1
                                (session.tones - cell.row)
                    in
                        note :: session.score

        newSession =
            { session
                | board = (updateBoard session.board cell)
                , score = newScore
            }
    in
        newSession :: (List.filter (\s -> s.id /= cell.sessionId) model.sessions)


updateBoard : Board -> Cell -> Board
updateBoard board cell =
    let
        trackId =
            .trackId cell
    in
        List.take trackId board ++ (updateTrack (board !! trackId) cell) :: List.drop (trackId + 1) board


updateTrack : Maybe Track -> Cell -> Track
updateTrack track cell =
    let
        rowNum =
            .row cell
    in
        case track of
            Just t ->
                { t
                    | grid =
                        List.take rowNum (.grid t)
                            ++ (updateRow ((.grid t) !! rowNum) cell)
                            :: List.drop (rowNum + 1) (.grid t)
                }

            Nothing ->
                Track -1 "" "" "404s" [] []


updateRow : Maybe (List Int) -> Cell -> List Int
updateRow row cell =
    let
        colNum =
            .column cell
    in
        case row of
            Just r ->
                List.take colNum r ++ (.action cell) :: List.drop (colNum + 1) r

            Nothing ->
                []


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



-- SCORE


increment : Int -> Int -> Int
increment clock beats =
    case clock of
        0 ->
            0

        _ ->
            (clock % beats) + 1


playNotes : Int -> Score -> List (Cmd msg)
playNotes clock score =
    List.filter (\n -> .beat n == clock) score
        |> List.map play


removeNote : Cell -> Score -> Score
removeNote cell score =
    List.filter
        (\n ->
            (.trackId n /= .trackId cell)
                || (.beat n - 1 /= .column cell)
                || (13 - .tone n /= .row cell)
        )
        score



-- SERVER_UPDATE


serverUpdateModel : Maybe ServerMessage -> Model -> Model
serverUpdateModel serverMessage model =
    case serverMessage of
        Just sm ->
            case sm.messageId of
                100 ->
                    serverUpdateSession sm model

                102 ->
                    serverNewSession sm model

                105 ->
                    case sm.payload of
                        SessionIds ids ->
                            let
                                sessionLists =
                                    model.sessionLists

                                newSessions =
                                    List.sort ids

                                newSessionsLists =
                                    { sessionLists | allSessions = newSessions }
                            in
                                { model
                                    | sessionLists = newSessionsLists
                                }

                        _ ->
                            Debug.log "105: Payload mismatch" model

                107 ->
                    case sm.payload of
                        DisconnectMessage msg ->
                            { model
                                | sessionId = 0
                                , serverMessage = "The server disconnected you."
                            }

                        _ ->
                            Debug.log "107: Payload mismatch" model

                111 ->
                    serverUpdateTrackStatus sm model

                113 ->
                    case sm.payload of
                        ClientInit id sessionList ->
                            let
                                sessionLists =
                                    model.sessionLists

                                newSessions =
                                    List.sort sessionList

                                newSessionsLists =
                                    { sessionLists | allSessions = newSessions }
                            in
                                { model | clientId = id, sessionLists = newSessionsLists }

                        _ ->
                            Debug.log "113: Payload mismatch" model

                114 ->
                    case sm.payload of
                        Error msg ->
                            Debug.log ("Error: " ++ msg) model

                        _ ->
                            Debug.log "114: Payload mismatch" model

                _ ->
                    Debug.log "Bad messageId" model

        Nothing ->
            Debug.log "Decode failure" model


serverUpdateSession : ServerMessage -> Model -> Model
serverUpdateSession serverMessage model =
    case serverMessage.payload of
        SessionMessage su ->
            let
                session =
                    Maybe.withDefault (emptySession 0)
                        (List.head
                            (List.filter (\s -> s.id == su.sessionId) model.sessions)
                        )

                board =
                    session.board

                newBoard =
                    serverUpdateBoard board su.boardUpdate model.clientId model.sessionId su.sessionId

                newScore =
                    List.concatMap
                        (\t -> serverUpdateScore t board session.tones model.clientId model.sessionId su.sessionId)
                        su.boardUpdate

                newSession =
                    { session
                        | board = newBoard
                        , clients = su.clientsUpdate
                        , tempo = su.tempoUpdate
                        , score = newScore
                    }

                newSessions =
                    newSession
                        :: (List.filter (\s -> s.id /= su.sessionId) model.sessions)
            in
                { model | sessions = newSessions }

        _ ->
            Debug.log ((toString (serverMessage.messageId)) ++ ": Payload mismatch") model


serverNewSession : ServerMessage -> Model -> Model
serverNewSession serverMessage model =
    case serverMessage.payload of
        SessionMessage su ->
            let
                session =
                    emptySession su.sessionId

                board =
                    session.board

                newBoard =
                    serverUpdateBoard board su.boardUpdate model.clientId model.sessionId su.sessionId

                newSession =
                    { session
                        | board = newBoard
                        , clients = su.clientsUpdate
                        , tempo = su.tempoUpdate
                    }

                newSessions =
                    newSession :: model.sessions

                sessionLists =
                    model.sessionLists

                newSessionsLists =
                    { sessionLists | allSessions = List.sort (su.sessionId :: sessionLists.allSessions) }
            in
                { model | sessions = newSessions, sessionLists = newSessionsLists }

        _ ->
            Debug.log ((toString (serverMessage.messageId)) ++ ": Payload mismatch") model


serverUpdateBoard : Board -> List TrackUpdate -> ClientId -> SessionId -> SessionId -> Board
serverUpdateBoard board boardUpdate clientId sessionId suId =
    List.map (\t -> serverUpdateTrack t boardUpdate clientId sessionId suId) board


serverUpdateTrack : Track -> List TrackUpdate -> ClientId -> SessionId -> SessionId -> Track
serverUpdateTrack track boardUpdate clientId sessionId suId =
    let
        trackUpdate =
            Maybe.withDefault
                { trackId = track.trackId
                , clientId = track.clientId
                , username = track.username
                , grid = track.grid
                }
                (List.head
                    (List.filter (\tu -> tu.trackId == track.trackId) boardUpdate)
                )
    in
        if track.clientId == clientId && suId == sessionId then
            track
        else
            { track | grid = trackUpdate.grid, clientId = trackUpdate.clientId, username = trackUpdate.username }


serverUpdateScore : TrackUpdate -> Board -> Int -> ClientId -> SessionId -> SessionId -> Score
serverUpdateScore tu board tones clientId sessionId suId =
    if tu.clientId == clientId && suId == sessionId then
        let
            track =
                List.head (List.filter (\t -> t.trackId == tu.trackId) board)
        in
            case track of
                Just t ->
                    readGrid t.grid t.trackId tones

                Nothing ->
                    []
    else
        readGrid tu.grid tu.trackId tones


readGrid : List (List Int) -> TrackId -> Int -> List Note
readGrid grid trackId tones =
    let
        rows =
            List.map (List.indexedMap (,)) grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\r -> readRow trackId tones r) tupleGrid


readRow : TrackId -> Int -> ( Int, List ( Int, Int ) ) -> List Note
readRow trackId tones row =
    List.map (\c -> readCell trackId tones (Tuple.first row) c) (Tuple.second row)


readCell : TrackId -> Int -> Int -> ( Int, Int ) -> Note
readCell trackId tones row c =
    let
        col =
            Tuple.first c

        action =
            Tuple.second c
    in
        case action of
            -- TODO: Re-work to not add empty notes
            0 ->
                Note trackId (col + 1) 0 (tones - row)

            _ ->
                Note trackId (col + 1) 1 (tones - row)


serverUpdateTrackStatus : ServerMessage -> Model -> Model
serverUpdateTrackStatus serverMessage model =
    case serverMessage.payload of
        TrackRequestResponse status sessionId trackId ->
            if status then
                let
                    session =
                        Maybe.withDefault
                            (emptySession sessionId)
                            (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                    newTrack =
                        updateTrackUser trackId model.clientId model.username session.board

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
                        case List.member session.id sessionLists.clientSessions of
                            True ->
                                sessionLists.clientSessions

                            False ->
                                List.sort (session.id :: sessionLists.clientSessions)

                    newSessionLists =
                        { sessionLists | clientSessions = newClientSessions }
                in
                    { model | sessions = newSessions, sessionLists = newSessionLists }
            else
                model

        _ ->
            Debug.log "111: Payload mismatch" model

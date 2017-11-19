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
import WebSocket


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddSession newId ->
            ( model
            , WebSocket.send "ws://localhost:8795" (encodeMessage model.clientId 101 (object []))
            )

        Broadcast selectedSessions track ->
            ( model
            , WebSocket.send "ws://localhost:8795"
                (encodeMessage model.clientId 108 (encodeBroadcast selectedSessions (encodeTrack track)))
            )

        Disconnect ->
            -- TODO: Does this send a message before navigating away?
            ( model
            , WebSocket.send "ws://localhost:8795" (encodeMessage model.clientId 106 (object []))
            )

        IncomingMessage rawMessage ->
            let
                serverMessage =
                    case Debug.log "serverMessage" (Json.Decode.decodeString decodeServerMessage rawMessage) of
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
                sessionLists =
                    model.sessionLists

                newSelectedSessions =
                    List.filter (\id -> id /= sessionId) sessionLists.selectedSessions

                newSessionLists =
                    { sessionLists | selectedSessions = newSelectedSessions }

                -- TODO: remove client from any tracks they hold? Or on response from server?
            in
                ( { model | sessionLists = newSessionLists }
                , WebSocket.send "ws://localhost:8795"
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

                websocketMessage =
                    case newRoute of
                        SessionRoute id ->
                            WebSocket.send "ws://localhost:8795"
                                (encodeMessage model.clientId 103 (encodeSessionId id))

                        Home ->
                            -- TODO: sufficient to use the same message, but 0 for home?
                            -- or is this implicit when LeaveSession
                            WebSocket.send "ws://localhost:8795"
                                (encodeMessage model.clientId 103 (encodeSessionId 0))

                        NotFoundRoute ->
                            WebSocket.send "ws://localhost:8795"
                                (encodeMessage model.clientId 114 (encodeError "Route not found"))
            in
                ( { model | route = newRoute, sessionId = newSessionId, sessions = newSessions }
                  -- , WebSocket.send "ws://localhost:8795" ("Requesting " ++ toString (session.id))
                , websocketMessage
                )

        ReleaseTrack sessionId trackId clientId ->
            --TODO: Send WS message
            let
                session =
                    Maybe.withDefault
                        (emptySession sessionId)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                newTrack =
                    updateTrackUser trackId clientId "" session.board

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
                , WebSocket.send "ws://localhost:8795"
                    (encodeMessage model.clientId 110 (encodeTrackRequest sessionId trackId))
                )

        RequestTrack sessionId trackId clientId ->
            --TODO: This will be a WS message only
            let
                session =
                    Maybe.withDefault
                        (emptySession sessionId)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                newTrack =
                    updateTrackUser trackId clientId model.username session.board

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
                ( { model | sessions = newSessions, sessionLists = newSessionLists }
                , WebSocket.send "ws://localhost:8795"
                    (encodeMessage model.clientId 109 (encodeTrackRequest sessionId trackId))
                )

        SelectName ->
            let
                input =
                    model.input

                message =
                    encodeMessage model.clientId 112 (encodeNickname input)
            in
                ( { model | username = input }, WebSocket.send "ws://localhost:8795" message )

        Send sessionId ->
            let
                session =
                    Maybe.withDefault
                        (emptySession 0)
                        (List.head (List.filter (\s -> s.id == sessionId) model.sessions))
            in
                ( model
                , WebSocket.send "ws://localhost:8795"
                    (encodeMessage model.clientId 101 (encodeSession session))
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

                        -- , messages = [ toString sessionId ]
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
                    -- TODO: implement
                    model

                102 ->
                    serverUpdateSession sm model

                105 ->
                    case sm.payload of
                        SessionIds ids ->
                            let
                                sessionLists =
                                    model.sessionLists

                                newSessions =
                                    List.sort ids

                                newSessionsLists =
                                    { sessionLists | sessions = newSessions }
                            in
                                { model
                                    | sessionLists = newSessionsLists
                                }

                        _ ->
                            Debug.log "105: Payload mismatch" model

                107 ->
                    case sm.payload of
                        DisconnectMessage msg ->
                            -- TODO: test if this re-routes correctly
                            { model
                                | sessionId = 0
                                , errorMessage = "The server disconnected you."
                            }

                        _ ->
                            Debug.log "107: Payload mismatch" model

                111 ->
                    -- TODO: status message needs to be more distinct, request or release?
                    model

                113 ->
                    case sm.payload of
                        ClientId id ->
                            { model | clientId = id }

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
        SessionMessage sessionId clientsUpdate tempoUpdate boardUpdate ->
            let
                session =
                    Maybe.withDefault (emptySession 0)
                        (List.head
                            (List.filter (\s -> s.id == sessionId) model.sessions)
                        )

                board =
                    session.board

                newBoard =
                    serverUpdateBoard board boardUpdate

                newSession =
                    { session
                        | board = newBoard
                        , clients = clientsUpdate
                        , tempo = tempoUpdate
                    }

                newSessions =
                    newSession
                        :: (List.filter (\s -> s.id /= sessionId) model.sessions)
            in
                { model | sessions = newSessions }

        _ ->
            Debug.log ((toString (serverMessage.messageId)) ++ ": Payload mismatch") model


serverUpdateBoard : Board -> List TrackMessage -> Board
serverUpdateBoard board boardUpdate =
    List.map (\t -> serverTrackUpdate t boardUpdate) board


serverTrackUpdate : Track -> List TrackMessage -> Track
serverTrackUpdate track boardUpdate =
    let
        trackUpdate =
            Maybe.withDefault
                { trackId = track.trackId, clientId = track.clientId, grid = track.grid }
                (List.head
                    (List.filter (\tu -> tu.trackId == track.trackId) boardUpdate)
                )
    in
        { track | grid = trackUpdate.grid, clientId = trackUpdate.clientId }

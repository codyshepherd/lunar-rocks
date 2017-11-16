module Update exposing (..)

import Data exposing (..)
import Json.Encode exposing (encode, Value, string, int, float, bool, list, object)
import List.Extra exposing ((!!))
import Models exposing (..)
import Msgs exposing (..)
import Ports exposing (play)
import Routing exposing (parseLocation)
import WebSocket


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                            WebSocket.send "ws://localhost:8795" (encodeMessage model.clientId 103 (int id))

                        Home ->
                            -- TODO: Routing for home, get last session id
                            -- WebSocket.send "ws://localhost:8080/lobby" (encodeMessage model.clientId 104 (int id))
                            WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ toString (newSessionId))

                        NotFoundRoute ->
                            WebSocket.send "ws://localhost:8080/lobby"
                                (encodeMessage model.clientId 114 (encodeError "Route not found"))
            in
                ( { model | route = newRoute, sessionId = newSessionId, sessions = newSessions }
                  -- , WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ toString (session.id))
                , websocketMessage
                )

        AddSession newId ->
            -- let
            --     sessions =
            --         model.sessions
            --     newSessions =
            --         { sessions | sessions = (model.sessions.sessions ++ [ newId ]) }
            -- in
            -- ( { model | sessions = newSessions }
            -- , WebSocket.send "ws://localhost:8080/lobby" ("Adding " ++ (toString newId))
            ( model
            , WebSocket.send "ws://localhost:8795" (encodeMessage model.clientId 101 (object []))
            )

        Broadcast selectedSessions ->
            -- TODO: Broadcast to server
            ( model, Cmd.none )

        UpdateBoard cell ->
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

                newSessions =
                    newSession :: (List.filter (\s -> s.id /= cell.sessionId) model.sessions)
            in
                ( { model | sessions = newSessions }
                , WebSocket.send "ws://localhost:8795"
                    (encodeMessage model.clientId 101 (encodeSession newSession))
                )

        UserInput newInput ->
            ( { model | input = newInput }, Cmd.none )

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

        -- Send ->
        --     ( model, WebSocket.send "ws://localhost:8080/lobby" session.input )
        SelectName ->
            let
                input =
                    model.input

                message =
                    encodeMessage model.clientId 112 (encodeNickname input)
            in
                ( { model | username = input }, WebSocket.send "ws://localhost:8795" message )

        --( { model | username = input }, WebSocket.send "ws://localhost:8080/lobby" message )
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

        IncomingMessage str ->
            -- let
            --     session =
            --         case List.head (List.filter (\s -> s.id == sessionId) model.sessions) of
            --             Just session ->
            --                 session
            --             Nothing ->
            --                 emptySession 0
            --     newSession =
            --         { session | messages = (session.messages ++ [ str ]) }
            --     newSessions =
            --         newSession :: model.sessions
            -- in
            --     ( { model | sessions = newSessions }, Cmd.none )
            ( model, Cmd.none )

        WindowResize size ->
            ( { model | windowSize = size }, Cmd.none )


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

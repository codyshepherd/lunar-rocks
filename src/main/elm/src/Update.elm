module Update exposing (..)

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

                board =
                    model.session.board

                newBoard =
                    [ Track 0 0 "" "Synth" (List.repeat 13 (List.repeat 8 0))
                    , Track 1 0 "" "Drums" (List.repeat 13 (List.repeat 8 0))
                    ]

                clock =
                    model.session.clock

                session =
                    model.session

                newSession =
                    case newRoute of
                        Models.SessionRoute id ->
                            { session | id = id, clock = 1, board = newBoard, input = "", messages = [] }

                        Models.Home ->
                            { session | id = 0, clock = 0, board = newBoard, input = "", messages = [] }

                        Models.NotFoundRoute ->
                            { session | id = 0, clock = 0, board = newBoard, input = "", messages = [] }
            in
                ( { model | route = newRoute, session = newSession, score = [] }
                , WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ toString (session.id))
                )

        AddSession newId ->
            let
                sessions =
                    model.sessions

                newSessions =
                    { sessions | sessions = (model.sessions.sessions ++ [ newId ]) }
            in
                ( { model | sessions = newSessions }
                , WebSocket.send "ws://localhost:8080/lobby" ("Adding " ++ (toString newId))
                )

        Broadcast selectedSessions ->
            -- TODO: Broadcast to server
            ( model, Cmd.none )

        UpdateBoard cell ->
            let
                score =
                    case cell.action of
                        0 ->
                            (removeNote cell model.score)

                        _ ->
                            let
                                note =
                                    Note
                                        cell.trackId
                                        (cell.column + 1)
                                        1
                                        (model.session.tones - cell.row)
                            in
                                note :: model.score

                session =
                    model.session

                newSession =
                    { session
                        | board = (updateBoard model.session.board cell)
                    }
            in
                ( { model | session = newSession, score = score }, Cmd.none )

        UserInput newInput ->
            let
                session =
                    model.session

                newSession =
                    { session | input = newInput }
            in
                ( { model | session = newSession }, Cmd.none )

        ReleaseTrack trackId clientId ->
            --TODO: Send WS message
            let
                newTrack =
                    updateTrackUser trackId clientId "" model.session.board

                newBoard =
                    List.take trackId model.session.board
                        ++ newTrack
                        :: List.drop (trackId + 1) model.session.board

                session =
                    model.session

                newSession =
                    { session | board = newBoard }

                sessions =
                    model.sessions

                newClientSessions =
                    List.filter (\cs -> cs /= session.id) sessions.clientSessions

                newSelectedSessions =
                    List.filter (\cs -> cs /= session.id) sessions.selectedSessions

                newSessions =
                    { sessions | clientSessions = newClientSessions, selectedSessions = newSelectedSessions }
            in
                ( { model | session = newSession, sessions = newSessions }, Cmd.none )

        RequestTrack trackId clientId ->
            --TODO: This will be a WS message only
            let
                newTrack =
                    updateTrackUser trackId clientId model.username model.session.board

                newBoard =
                    List.take trackId model.session.board
                        ++ newTrack
                        :: List.drop (trackId + 1) model.session.board

                session =
                    model.session

                newSession =
                    { session | board = newBoard }

                sessions =
                    model.sessions

                newClientSessions =
                    case List.member session.id sessions.clientSessions of
                        True ->
                            sessions.clientSessions

                        False ->
                            List.sort (session.id :: sessions.clientSessions)

                newSessions =
                    { sessions | clientSessions = newClientSessions }
            in
                ( { model | session = newSession, sessions = newSessions }, Cmd.none )

        Send ->
            ( model, WebSocket.send "ws://localhost:8080/lobby" model.session.input )

        SelectName ->
            let
                input =
                    model.session.input
            in
                ( { model | username = input }, Cmd.none )

        Tick time ->
            let
                session =
                    model.session

                newSession =
                    { session
                        | clock = increment session.clock session.beats

                        -- , messages = ((toString model.score) :: model.session.messages)
                        , messages = [ toString model.score ]
                    }
            in
                { model
                    | session = newSession
                }
                    ! [ Cmd.batch (playNotes model.session.clock model.score) ]

        ToggleSessionButton sessionId ->
            let
                sessions =
                    model.sessions

                selectedSessions =
                    sessions.selectedSessions

                newSelectedSessions =
                    case List.member sessionId selectedSessions of
                        True ->
                            List.filter (\s -> s /= sessionId) selectedSessions

                        False ->
                            List.sort (sessionId :: selectedSessions)

                newSessions =
                    { sessions | selectedSessions = newSelectedSessions }
            in
                ( { model | sessions = newSessions }, Cmd.none )

        IncomingMessage str ->
            let
                session =
                    model.session

                newSession =
                    { session | messages = (model.session.messages ++ [ str ]) }
            in
                ( { model | session = newSession }, Cmd.none )

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
                Track -1 -1 "" "404s" []


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
                Track -1 -1 "" "404s" []


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

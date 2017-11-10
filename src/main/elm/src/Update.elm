module Update exposing (..)

import List.Extra exposing ((!!))
import Models exposing (Board, Cell, Model, Note, SessionId, Score, Track)
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

                session =
                    model.session

                newSession =
                    case newRoute of
                        Models.SessionRoute id ->
                            { session | id = id, input = "", messages = [] }

                        Models.Home ->
                            { session | id = "home", input = "", messages = [] }

                        Models.NotFoundRoute ->
                            { session | id = "", input = "", messages = [] }
            in
                ( { model | route = newRoute, session = newSession }
                , WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ session.id)
                )

        AddSession newId ->
            ( { model | sessions = (model.sessions ++ [ newId ]) }
            , WebSocket.send "ws://localhost:8080/lobby" ("Adding " ++ newId)
            )

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

        Send ->
            let
                session =
                    model.session
            in
                ( model, WebSocket.send "ws://localhost:8080/lobby" session.input )

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

        IncomingMessage str ->
            let
                session =
                    model.session

                newSession =
                    { session | messages = (model.session.messages ++ [ str ]) }
            in
                ( { model | session = newSession }, Cmd.none )


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
                Track -1 -1 []


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

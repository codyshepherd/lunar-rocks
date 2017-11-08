module Update exposing (..)

import Models exposing (Model, SessionId)
import Msgs exposing (..)
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
                    case newRoute of
                        Models.SessionRoute id ->
                            Models.Session
                                id
                                model.session.tempo
                                model.session.clients
                                model.session.board
                                ""
                                []

                        Models.Home ->
                            Models.Session
                                "home"
                                model.session.tempo
                                model.session.clients
                                model.session.board
                                ""
                                []

                        Models.NotFoundRoute ->
                            Models.Session
                                ""
                                model.session.tempo
                                model.session.clients
                                model.session.board
                                ""
                                []
            in
                ( { model | route = newRoute, session = session }
                , WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ session.id)
                )

        AddSession newId ->
            ( { model | sessions = (model.sessions ++ [ newId ]) }
            , WebSocket.send "ws://localhost:8080/lobby" ("Adding " ++ newId)
            )

        UpdateBoard cell ->
            let
                session =
                    Models.Session
                        model.session.id
                        model.session.tempo
                        model.session.clients
                        model.session.board
                        model.session.input
                        (model.session.messages ++ [ (toString cell) ])
            in
                ( { model | session = session }, Cmd.none )

        UserInput newInput ->
            let
                session =
                    Models.Session
                        model.session.id
                        model.session.tempo
                        model.session.clients
                        model.session.board
                        newInput
                        model.session.messages
            in
                ( { model | session = session }, Cmd.none )

        Send ->
            let
                session =
                    model.session
            in
                ( model, WebSocket.send "ws://localhost:8080/lobby" session.input )

        IncomingMessage str ->
            let
                session =
                    Models.Session
                        model.session.id
                        model.session.tempo
                        model.session.clients
                        model.session.board
                        model.session.input
                        (model.session.messages ++ [ str ])
            in
                ( { model | session = session }, Cmd.none )

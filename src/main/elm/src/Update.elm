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
                            Models.Session id "" []

                        Models.Home ->
                            Models.Session "home" "" []

                        Models.NotFoundRoute ->
                            Models.Session "" "" []
            in
                ( { model | route = newRoute, session = session }
                , WebSocket.send "ws://localhost:8080/lobby" ("Requesting " ++ session.id)
                )

        AddSession newId ->
            ( { model | sessions = (model.sessions ++ [ newId ]) }
            , WebSocket.send "ws://localhost:8080/lobby" ("Adding " ++ newId)
            )

        Input newInput ->
            let
                session =
                    Models.Session model.session.id newInput model.session.messages
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
                    Models.Session model.session.id model.session.input (model.session.messages ++ [ str ])
            in
                ( { model | session = session }, Cmd.none )

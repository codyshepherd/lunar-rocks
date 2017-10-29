module Main exposing (..)

import Models exposing (Model, SessionId, initialModel)
import Msgs exposing (..)
import Navigation exposing (Location)
import Routing exposing (parseLocation)
import Views exposing (view)
import Update exposing (update)
import WebSocket


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location
    in
        ( initialModel currentRoute, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8080/lobby" IncomingMessage

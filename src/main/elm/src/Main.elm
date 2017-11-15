module Main exposing (..)

import Models exposing (Model, SessionId, initialModel)
import Msgs exposing (..)
import Navigation exposing (Location)
import Routing exposing (parseLocation)
import Task exposing (perform)
import Time exposing (every, second)
import Views exposing (view)
import Update exposing (update)
import WebSocket
import Window exposing (size)


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
        ( initialModel currentRoute, Task.perform WindowResize Window.size )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WebSocket.listen "ws://localhost:8795" IncomingMessage
        --[ WebSocket.listen "ws://localhost:8080/lobby" IncomingMessage
        , every second Tick
        , Window.resizes (\{ width, height } -> WindowResize { width = width, height = width })
        ]

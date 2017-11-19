module Main exposing (..)

import Models exposing (Model, SessionId, initialModel, websocketServer)
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
        [ WebSocket.listen websocketServer IncomingMessage
        , WebSocket.keepAlive websocketServer
        , every (second * 0.5) Tick
        , Window.resizes (\{ width, height } -> WindowResize { width = width, height = width })
        ]

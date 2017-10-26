module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import WebSocket


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { input : String
    , messages : List String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" [], Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | IncomingMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { input, messages } =
    case msg of
        Input newInput ->
            ( Model newInput messages, Cmd.none )

        Send ->
            ( Model "" messages, WebSocket.send "ws://localhost:8080" input )

        IncomingMessage str ->
            ( Model input (messages ++ [ str ]), Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8080" IncomingMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ style [ ( "fontWeight", "bold" ) ] ] [ text "~WEBSOCKET TEST~" ]
        , div [] (List.map viewMessage model.messages)
        , input [ onInput Input, onEnter Send ] []
        ]


viewMessage : String -> Html msg
viewMessage msg =
    div [] [ text msg ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter keycode =
            if keycode == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)

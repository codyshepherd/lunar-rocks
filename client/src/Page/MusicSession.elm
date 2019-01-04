module Page.MusicSession exposing (Model, Msg(..), init, subscriptions, update, view)

import Element exposing (..)
import Element.Events exposing (..)
import Element.Input as Input


type alias Model =
    Int


init : ( Model, Cmd Msg )
init =
    ( 0, Cmd.none )



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( model + 1, Cmd.none )

        Decrement ->
            ( model - 1, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 10 ]
        [ column [ centerX ]
            [ Input.button [] { onPress = Just Increment, label = text "+" }
            , text (String.fromInt model)
            , Input.button [] { onPress = Just Decrement, label = text "-" }
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

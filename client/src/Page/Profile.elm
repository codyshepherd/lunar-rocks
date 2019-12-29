module Page.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Element exposing (..)
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Session exposing (Session)


type alias Model =
    { session : Session
    , counter : Int
    }


init : Session -> String -> ( Model, Cmd Msg )
init session username =
    ( { session = session
      , counter = 0
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, Cmd.none )

        Decrement ->
            ( { model | counter = model.counter - 1 }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 10 ]
        [ column [ centerX, spacing 10, Font.family Fonts.quattrocentoFont ]
            [ text "Viewing the home page"
            , row [ width fill ]
                [ column [ centerX ]
                    [ Input.button [ centerX ] { onPress = Just Increment, label = text "+" }
                    , el [ centerX ] <| text (String.fromInt model.counter)
                    , Input.button [ centerX ] { onPress = Just Decrement, label = text "-" }
                    ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

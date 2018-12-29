module Page.Login exposing (Model, Msg(..), init, update, view)

import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts


type alias Model =
    { username : String
    , password : String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" "", Cmd.none )



-- UPDATE


type Msg
    = UpdateUsername String
    | UpdatePassword String
    | SignIn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateUsername newUsername ->
            ( { model | username = newUsername }, Cmd.none )

        UpdatePassword newPassword ->
            ( { model | password = newPassword }, Cmd.none )

        SignIn ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 150, Font.family Fonts.quattrocentoFont ]
        [ column [ centerX, width (px 375), spacing 25 ]
            [ row [ centerX ] [ el [ Font.family Fonts.cinzelFont, Font.size 27 ] <| text "Sign in to Lunar Rocks" ]
            , row
                [ centerX
                , paddingXY 0 25
                , width fill
                , Background.color (rgba 0.2 0.2 0.2 1)
                , Border.color (rgba 0.36 0.38 0.45 0.1)
                , Border.rounded 3
                , Border.width 1
                ]
                [ column [ centerX, width (px 300), spacing 20 ]
                    [ Input.username
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.username
                        , placeholder = Nothing
                        , onChange = \newUsername -> UpdateUsername newUsername
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username")
                        }
                    , Input.newPassword
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.password
                        , placeholder = Nothing
                        , onChange = \newPassword -> UpdatePassword newPassword
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Password")
                        , show = False
                        }
                    , Input.button
                        [ Border.color (rgba 0.36 0.38 0.45 1)
                        , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
                        , paddingXY 32 16
                        , Border.rounded 3
                        , Border.width 2
                        , width fill
                        ]
                        { onPress = Just SignIn
                        , label = text "Sign in"
                        }
                    ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

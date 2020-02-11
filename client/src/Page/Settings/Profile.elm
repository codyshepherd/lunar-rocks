module Page.Settings.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Account exposing (Account)
import Avatar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Fonts
import User exposing (User)


type alias Model =
    { account : Account
    }


init : User -> ( Model, Cmd Msg )
init user =
    let
        account =
            User.account user
    in
    ( { account = account
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Nop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nop ->
            ( model, Cmd.none )


view : Model -> Element Msg
view model =
    row
        [ centerX
        , width (px 1000)
        , paddingXY 0 40
        , spacing 40
        ]
        [ settingsNav
        , column [ centerX, width (px 740), height fill, spacing 20 ] <|
            [ row [ width fill ]
                [ el [ Font.size 50, Font.family Fonts.cinzelFont ] <| text "Profile"
                , link
                    [ alignRight
                    , centerY
                    , Border.color (rgba 0.36 0.38 0.45 1)
                    , paddingXY 10 10
                    , Border.rounded 3
                    , Border.width 1
                    , Font.family Fonts.cinzelFont
                    , Font.size 18
                    , mouseOver
                        [ Background.color (rgb255 51 57 77)
                        ]
                    ]
                  <|
                    { url = "/" ++ Account.username model.account, label = text "View Public Profile" }
                ]
            , row [ spacing 20 ]
                [ column [ alignTop, width (px 500), spacing 15 ]
                    [ row
                        [ width fill
                        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                        , Border.color (rgba 0.22 0.24 0.28 1)
                        ]
                        [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "Display Name")
                        ]
                    , paragraph []
                        [ el [ Font.size 18 ] <|
                            text <|
                                "Your username is "
                                    ++ Account.username model.account
                                    ++ ". We will add a display name option soon."
                        ]
                    , row
                        [ width fill
                        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                        , Border.color (rgba 0.22 0.24 0.28 1)
                        ]
                        [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "About You")
                        ]
                    , paragraph []
                        [ el [ Font.size 18 ] <| text "Fields for bio, location, and website will go here."
                        ]
                    ]
                , column [ alignTop, width (px 240), spacing 15 ]
                    [ row
                        [ width fill
                        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                        , Border.color (rgba 0.22 0.24 0.28 1)
                        ]
                        [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "Profile Picture")
                        ]
                    , row
                        [ centerX
                        , width (px 200)
                        , height (px 200)
                        , Border.widthEach { bottom = 1, left = 1, right = 1, top = 1 }
                        , Border.color (rgb 0.22 0.24 0.28)
                        ]
                        [ el [] <|
                            image [ height (px 200), clip ] <|
                                Avatar.imageMeta <|
                                    Account.avatar model.account
                        ]
                    ]
                ]
            ]
        ]


settingsNav : Element Msg
settingsNav =
    column
        [ width (px 210)
        , alignTop
        , Border.color (rgba 0.36 0.38 0.45 1)
        , Border.rounded 3
        , Border.width 2
        ]
        [ el
            [ paddingXY 16 16
            , width fill
            , Font.color (rgb255 200 200 200)
            , Border.color (rgba 0.36 0.38 0.45 1)
            , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
            , Background.color (rgb255 51 57 77)
            ]
            (text "Settings")
        , link
            [ Border.color (rgba 0.36 0.38 0.45 1)
            , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
            , paddingXY 16 16
            , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
            , width fill
            ]
            { url = "/settings/account", label = text "Account" }
        , link
            [ paddingXY 16 16
            , width fill
            ]
            { url = "/settings/profile", label = text "Profile" }
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

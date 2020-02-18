module Page.Settings.SettingsNav exposing (account, profile, view)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes


type ActivePage
    = Account
    | Profile


account : ActivePage
account =
    Account


profile : ActivePage
profile =
    Profile


view : ActivePage -> Element msg
view activePage =
    column
        [ width (px 210)
        , alignTop
        , Border.color (rgba 0.36 0.38 0.45 1)
        , Border.rounded 3
        , Border.width 2
        ]
        [ row
            [ width fill
            , padding 16
            , Border.color (rgba 0.36 0.38 0.45 1)
            , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
            ]
            [ el
                [ Font.color (rgb255 200 200 200)
                ]
                (text "Settings")
            ]
        , column [ paddingXY 20 22, spacing 25 ]
            [ row
                [ width fill
                , spacing 10
                , case activePage of
                    Account ->
                        Font.color (rgb255 255 255 255)

                    Profile ->
                        Font.color (rgb255 175 175 175)
                ]
                [ el [] <|
                    html
                        (Html.i [ Html.Attributes.class "far fa-id-card" ] [])
                , link
                    []
                    { url = "/settings/account", label = text "Account" }
                ]
            , row
                [ width fill
                , spacing 12
                , case activePage of
                    Account ->
                        Font.color (rgb255 175 175 175)

                    Profile ->
                        Font.color (rgb255 255 255 255)
                ]
                [ el [] <|
                    html
                        (Html.i [ Html.Attributes.class "far fa-user-circle" ] [])
                , link
                    []
                    { url = "/settings/profile", label = text "Profile" }
                ]
            ]
        ]
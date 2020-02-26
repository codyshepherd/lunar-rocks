module Infobar exposing (Infobar, error, errorBottom, errorTop, success, successBottom, successTop, view)

import Browser.Dom as Dom
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Routes exposing (Route)


type Infobar
    = Infobar Status String Dom.Viewport Position


type Status
    = Success
    | Error


type Position
    = Top
    | Bottom


success : Dom.Viewport -> Route -> String -> Infobar
success viewport route info =
    case route of
        Routes.ProfileSettings ->
            Infobar Success info viewport Top

        Routes.AccountSettings ->
            Infobar Success info viewport Top

        _ ->
            Infobar Success info viewport Bottom


error : Dom.Viewport -> Route -> String -> Infobar
error viewport route info =
    case route of
        Routes.ProfileSettings ->
            Infobar Error info viewport Top

        Routes.AccountSettings ->
            Infobar Error info viewport Top

        _ ->
            Infobar Error info viewport Bottom


successTop : Dom.Viewport -> String -> Infobar
successTop viewport info =
    Infobar Success info viewport Top


successBottom : Dom.Viewport -> String -> Infobar
successBottom viewport info =
    Infobar Success info viewport Bottom


errorTop : Dom.Viewport -> String -> Infobar
errorTop viewport info =
    Infobar Error info viewport Top


errorBottom : Dom.Viewport -> String -> Infobar
errorBottom viewport info =
    Infobar Error info viewport Bottom


view : Infobar -> msg -> Element msg
view (Infobar status info viewport position) msg =
    let
        offset =
            round viewport.viewport.y

        viewportHeight =
            round viewport.viewport.height

        sceneHeight =
            round viewport.scene.height
    in
    row
        (case position of
            Top ->
                [ width fill
                , paddingEach
                    { top = offset + 30
                    , left = 0
                    , right = 0
                    , bottom = 0
                    }
                ]

            Bottom ->
                [ alignBottom
                , width fill
                , paddingEach
                    { top = 0
                    , left = 0
                    , right = 0
                    , bottom = sceneHeight - viewportHeight + 30
                    }
                ]
        )
        [ row
            ([ centerX
             , paddingXY 0 6
             , spacing 5
             , Border.width 1
             , Border.rounded 4
             , Font.color (rgb255 255 255 255)
             ]
                ++ (case status of
                        Success ->
                            [ Background.color (rgb255 11 142 66)
                            , Border.color (rgb255 5 71 33)
                            ]

                        Error ->
                            [ Background.color (rgb255 179 25 25)
                            , Border.color (rgb255 89 13 13)
                            ]
                   )
            )
            [ el [ paddingEach { top = 10, right = 6, bottom = 10, left = 20 } ] <|
                html
                    (Html.i
                        [ case status of
                            Success ->
                                Html.Attributes.class "fa fa-check-circle"

                            Error ->
                                Html.Attributes.class "fa fa-minus-circle"
                        ]
                        []
                    )
            , el [ paddingEach { top = 10, right = 25, bottom = 10, left = 0 } ] (text info)
            , Input.button
                [ paddingXY 20 5
                , Border.widthEach { bottom = 0, left = 1, right = 0, top = 0 }
                , Border.color (rgb255 200 200 200)
                , mouseOver
                    [ Font.color (rgb255 200 200 200)
                    ]
                , focused
                    [ Border.glow (rgb255 0 0 0) 0 ]
                ]
                { onPress = Just msg
                , label = el [ centerX ] <| text "✕"
                }
            ]
        ]

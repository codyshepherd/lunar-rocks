module Infobar exposing (Infobar, error, success, view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes


type Infobar
    = Infobar Status String


type Status
    = Success
    | Error


success : String -> Infobar
success info =
    Infobar Success info


error : String -> Infobar
error info =
    Infobar Error info


view : Infobar -> msg -> Element msg
view (Infobar status info) msg =
    row
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
            [ paddingXY 20 10
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

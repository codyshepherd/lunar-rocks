module Views exposing (..)

import Color
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input
import Html


-- import Html exposing (Html, div, text, input, a, button, h2, hr)
-- import Html.Attributes exposing (..)

import Models exposing (..)
import Msgs exposing (..)
import Routing exposing (sessionPath, sessionsPath)
import Style exposing (..)
import Style.Border as Border
import Style.Color as Color
import Style.Font as Font


stylesheet : StyleSheet Styles variation
stylesheet =
    Style.styleSheet
        [ style None []
        , style Main []
        , style Navigation
            [ Font.size 36
            , Color.text Color.white
            , Color.background Color.darkCharcoal
            ]
        , style MessageInput
            [ Border.all 1 ]
        ]


view : Model -> Html.Html Msg
view model =
    Element.layout stylesheet <|
        column None
            []
            [ navigation
            , el None [ center, width (px 800) ] <|
                column Main [ spacing 50, paddingTop 20, paddingBottom 50 ] (page model)
            ]


navigation =
    row Navigation
        [ center
        , paddingTop 20
        , paddingBottom 20
        ]
        [ h1 None [] (text "Music") ]


page model =
    case model.route of
        Home ->
            [ textLayout None
                [ spacingXY 25 25
                , padding 60
                ]
                [ paragraph None
                    [ paddingBottom 10 ]
                    [ text "~HOME~" ]
                , textLayout None
                    []
                    (List.map viewSessionEntry model.sessions)
                , paragraph None
                    [ paddingTop 10 ]
                    [ button None [ onClick (AddSession (newId model.sessions)) ] (text "Add Session") ]
                ]
            ]

        SessionRoute id ->
            [ textLayout None
                [ spacingXY 25 25
                , padding 60
                ]
                [ paragraph None
                    [ paddingBottom 10 ]
                    [ text ("~SESSION " ++ id ++ "~") ]
                , textLayout None
                    []
                    (List.map viewMessage model.session.messages)
                , Input.text MessageInput
                    []
                    { label =
                        Input.placeholder
                            { label = Input.labelLeft (el None [ verticalCenter ] (text ""))
                            , text = "message"
                            }
                    , onChange = UserInput
                    , options = []
                    , value = ""
                    }
                , button None [ onClick Send ] (text "Send")
                ]
            ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


viewSessionEntry sessionId =
    paragraph None
        []
        [ link (sessionPath sessionId) <| el None [] (text ("Session " ++ sessionId)) ]


viewMessage msg =
    paragraph None [] [ text msg ]


newId : List SessionId -> SessionId
newId sessions =
    case List.head (List.reverse sessions) of
        Just head ->
            toString (Result.withDefault -1 (String.toInt head) + 1)

        Nothing ->
            "1"

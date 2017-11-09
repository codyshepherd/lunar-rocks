module Views exposing (..)

import Color
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input
import Html
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
        , style Container
            [ Color.background Color.darkCharcoal ]
        , style Play
            [ Color.background Color.darkBlue
            , Color.text Color.white
            ]
        , style Rest
            [ Color.text Color.white ]
        , style MessageInput
            [ Border.all 1 ]
        ]


view : Model -> Html.Html Msg
view model =
    Element.layout stylesheet <|
        column None
            []
            [ navigation
            , el None [ center, width (px 797) ] <|
                column Main [ paddingTop 20, paddingBottom 50 ] (page model)
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
                , padding 50
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
                [ spacingXY 25 25 ]
                ([ paragraph None
                    [ paddingBottom 10 ]
                    [ text ("~SESSION " ++ id ++ "~") ]
                 ]
                    ++ (viewBoard model.session.board)
                    ++ [ textLayout None
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
                )
            ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


viewSessionEntry sessionId =
    paragraph None
        []
        [ link (sessionPath sessionId) <| el None [] (text ("Session " ++ sessionId)) ]


viewMessage msg =
    paragraph None [] [ text msg ]


viewBoard board =
    List.map viewTrack board


viewTrack track =
    grid Container
        [ spacing 3 ]
        { columns = List.repeat 8 (px 97)
        , rows = List.repeat 13 (px 25)
        , cells =
            viewGrid (.trackId track) (.grid track)
        }


viewGrid : TrackId -> List (List Int) -> List (OnGrid (Element Styles variation Msg))
viewGrid trackId grid =
    let
        rows =
            List.map (List.indexedMap (,)) grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\r -> viewRow trackId r) tupleGrid


viewRow : TrackId -> ( Int, List ( Int, Int ) ) -> List (OnGrid (Element Styles variation Msg))
viewRow trackId row =
    List.map (\c -> viewCell trackId (Tuple.first row) c) (Tuple.second row)


viewCell : TrackId -> Int -> ( Int, Int ) -> OnGrid (Element Styles variation Msg)
viewCell trackId row c =
    let
        col =
            Tuple.first c

        action =
            Tuple.second c
    in
        cell
            { start = ( col, row )
            , width = 1
            , height = 1
            , content =
                let
                    act =
                        case action of
                            0 ->
                                Rest

                            _ ->
                                Play
                in
                    (el act
                        [ onClick (UpdateBoard { trackId = trackId, column = col, row = row, action = action }) ]
                        -- (text (toString action))
                        (text (""))
                    )
            }


newId : List SessionId -> SessionId
newId sessions =
    case List.head (List.reverse sessions) of
        Just head ->
            toString (Result.withDefault -1 (String.toInt head) + 1)

        Nothing ->
            "1"

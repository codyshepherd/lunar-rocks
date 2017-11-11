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


serif =
    [ Font.importUrl
        { url = "https://fonts.googleapis.com/css?family=Cinzel"
        , name = "Cinzel"
        }
    , Font.font "times new roman"
    , Font.font "times"
    , Font.font "serif"
    ]


sansSerif =
    [ Font.importUrl
        { url = "https://fonts.googleapis.com/css?family=Quattrocento+Sans"
        , name = "Quattrocento Sans"
        }
    , Font.font "helvetica"
    , Font.font "arial"
    , Font.font "sans-serif"
    ]


stylesheet : StyleSheet Styles variation
stylesheet =
    Style.styleSheet
        [ style None []
        , style Main
            [ Color.background (Color.rgb 40 40 40)
            , Color.text Color.white
            , Font.typeface sansSerif
            ]
        , style InstrumentLabel [ Font.size 20 ]
        , style Text [ Font.size 18 ]
        , style Navigation
            [ Border.bottom 1
            , Color.background (Color.rgb 39 39 39)
            , Color.border (Color.rgb 28 31 36)
            , Color.text Color.white
            ]
        , style Heading
            [ Font.typeface serif
            , Font.size 48
            ]
        , style SubHeading
            [ Font.typeface serif
            , Font.size 24
            ]
        , style GridBlock
            [ Color.background (Color.rgb 120 120 120) ]
        , style PlayPurple
            [ Color.background (Color.rgb 91 96 115)
            , Color.text Color.white
            ]
        , style PlayOrange
            [ Color.background (Color.rgb 215 88 19)
            , Color.text Color.white
            ]
        , style Rest
            [ Color.background (Color.rgb 150 150 150)
            , Color.text Color.white
            ]
        , style MessageInput
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 75 79 94)
            , Color.text Color.white
            ]
        , style SessionListing
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 91 96 115)
            , Color.text Color.white
            ]
        ]



-- Color.rgb 28 31 36
-- Color.rgb 171 0 0


view : Model -> Html.Html Msg
view model =
    Element.viewport stylesheet <|
        el Main [ minHeight (px (toFloat model.windowSize.height)) ] <|
            column Main
                []
                [ navigation
                , el None [ center, width (px 799) ] <|
                    column Main [ paddingTop 20, paddingBottom 50 ] (page model)
                ]


navigation : Element Styles variation Msg
navigation =
    row Navigation
        [ center
        , paddingTop 20
        , paddingBottom 20
        , spacing 5
        ]
        [ h1 Heading [] (text "Music") ]


page : Model -> List (Element Styles variation Msg)
page model =
    case model.route of
        Home ->
            [ h3 SubHeading
                [ paddingLeft 25 ]
                (text "MAKE MUSIC ACROSS THE WEB")
            , paragraph Text [ padding 25 ] [ text "Some general info and instructions." ]
            , textLayout None
                [ spacingXY 25 25
                , padding 25
                ]
                (case model.username of
                    "" ->
                        [ h3 SubHeading
                            [ paddingTop 10 ]
                            (text "SELECT A NICKNAME")
                        , column None
                            [ width (px 200) ]
                            [ row None
                                [ spacing 1 ]
                                [ Input.text MessageInput
                                    [ paddingLeft 2 ]
                                    { label =
                                        Input.placeholder
                                            { label = Input.hiddenLabel "Nickname"
                                            , text = "nickname"
                                            }
                                    , onChange = UserInput
                                    , options = []
                                    , value = ""
                                    }
                                , spacer 5
                                , button SessionListing [ paddingXY 7 0, onClick SelectName ] (text "->")
                                ]
                            ]
                        ]

                    _ ->
                        [ h3 SubHeading
                            [ paddingTop 10 ]
                            (text "SESSIONS")
                        , paragraph Text
                            []
                            [ text
                                ("Greetings " ++ model.username ++ "! Select a session below or start a new one.")
                            ]
                        , textLayout None [] (List.map viewSessionEntry model.sessions)
                        , paragraph None
                            []
                            [ button SessionListing
                                [ paddingXY 10 5, onClick (AddSession (newId model.sessions)) ]
                                (text "New Session")
                            ]
                        ]
                )
            ]

        SessionRoute id ->
            [ textLayout None
                [ spacing 1 ]
                ([ h3 SubHeading
                    [ paddingTop 20, paddingBottom 20 ]
                    (text ("SESSION " ++ id))
                 ]
                    ++ (viewBoard model.session.board model.session.beats model.session.tones model.clientId)
                    ++ [ textLayout None
                            [ paddingBottom 10 ]
                            (List.map viewMessage model.session.messages)
                       , Input.text MessageInput
                            []
                            { label =
                                Input.placeholder
                                    { label = Input.labelLeft (el None [ verticalCenter ] empty)
                                    , text = "message"
                                    }
                            , onChange = UserInput
                            , options = []
                            , value = ""
                            }
                       , spacer 10
                       , button SessionListing [ paddingXY 10 5, onClick Send ] (text "Send")
                       ]
                )
            ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


viewSessionEntry : SessionId -> Element Styles variation Msg
viewSessionEntry sessionId =
    button SessionListing
        [ paddingXY 10 5, spacingXY 0 10 ]
        (link (sessionPath sessionId) <| el None [] (text ("Session " ++ sessionId)))


viewMessage : String -> Element Styles variation Msg
viewMessage msg =
    paragraph None [] [ text msg ]


viewBoard : List Track -> Int -> Int -> Int -> List (Element Styles variation Msg)
viewBoard board beats tones clientId =
    List.concatMap (\t -> viewTrack t beats tones clientId) board


viewTrack : Track -> Int -> Int -> Int -> List (Element Styles variation Msg)
viewTrack track beats tones clientId =
    [ grid GridBlock
        [ spacing 1 ]
        { columns = List.repeat beats (px 99)
        , rows = List.repeat tones (px 12)
        , cells =
            viewGrid (.trackId track) (.grid track)
        }
    , paragraph None
        [ paddingTop 8, paddingBottom 30 ]
        (case track.username of
            "" ->
                [ el InstrumentLabel [] (text track.instrument)
                , button SessionListing
                    [ paddingXY 10 2, alignRight, onClick (RequestTrack track.trackId clientId) ]
                    (text "Request Track")
                ]

            _ ->
                [ el InstrumentLabel [] (text (track.username ++ " on " ++ track.instrument))
                , when
                    (clientId == track.clientId)
                    (button SessionListing
                        [ paddingXY 10 2, alignRight, onClick (ReleaseTrack track.trackId 0) ]
                        (text "Release Track")
                    )
                ]
        )
    ]


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
                                case trackId of
                                    0 ->
                                        PlayOrange

                                    _ ->
                                        PlayPurple
                in
                    (el act
                        [ onClick
                            (UpdateBoard
                                { trackId = trackId
                                , column = col
                                , row = row
                                , action = (action + 1) % 2
                                }
                            )
                        ]
                        empty
                    )
            }


newId : List SessionId -> SessionId
newId sessions =
    case List.head (List.reverse sessions) of
        Just head ->
            toString (Result.withDefault -1 (String.toInt head) + 1)

        Nothing ->
            "1"

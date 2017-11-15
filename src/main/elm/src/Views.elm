module Views exposing (..)

import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input
import Html
import Models exposing (..)
import Msgs exposing (..)
import Routing exposing (sessionPath, sessionsPath)
import Styles exposing (..)


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
                            (text "CHOOSE A NICKNAME")
                        , column None
                            [ width (px 200) ]
                            [ row None
                                [ spacing 1 ]
                                [ Input.text MessageInput
                                    [ paddingXY 2 3 ]
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
                                , button Button [ paddingXY 7 3, onClick SelectName ] (text "->")
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
                        , textLayout None [] (List.map viewSessionEntry model.sessions.sessions)
                        , paragraph None
                            []
                            [ button Button
                                [ paddingXY 10 5, onClick (AddSession (newId model.sessions.sessions)) ]
                                (text "New Session")
                            ]
                        ]
                )
            ]

        SessionRoute id ->
            -- TODO: Filter for current session - fix below
            -- let
            --     session =
            --         get session from sessions
            -- in
            [ textLayout None
                [ spacing 1 ]
                ([ h3 SubHeading
                    [ paddingTop 20, paddingBottom 20 ]
                    (text ("SESSION " ++ toString (id)))

                 -- ]
                 , row None
                    [ spacing 2 ]
                    -- ++ (viewBoard
                    --         model.session.board
                    --         model.clientId
                    --         model.session.beats
                    --         model.session.tones
                    --    )
                    [ column None [ spacing 1 ] (viewLabels model.session.board model.session.tones)
                    , column None
                        []
                        (viewBoard
                            model.session.board
                            model.clientId
                            model.session.beats
                            model.session.tones
                        )
                    ]
                 ]
                    ++ [ -- when ((List.length model.sessions.clientSessions) > 0)
                         --       (h3 SubHeading
                         --           [ paddingTop 20, paddingBottom 20 ]
                         --           (text "YOUR SESSIONS")
                         --       )
                         paragraph None
                            [ spacing 7 ]
                            (List.map
                                (\cs ->
                                    viewSessionButton
                                        cs
                                        model.sessions.selectedSessions
                                )
                                model.sessions.clientSessions
                            )
                       , spacer 10
                       , (let
                            selectedSessions =
                                model.sessions.selectedSessions
                          in
                            paragraph None
                                [ spacing 3 ]
                                [ when ((List.length selectedSessions) >= 1)
                                    (button
                                        Button
                                        [ paddingXY 10 2, onClick (Broadcast selectedSessions) ]
                                        (text "Broadcast")
                                    )
                                , when ((List.length selectedSessions) == 1)
                                    (button
                                        Button
                                        [ paddingXY 10 2 ]
                                        (link
                                            (sessionPath (Maybe.withDefault 0 (List.head selectedSessions)))
                                         <|
                                            el None [] (text "Goto")
                                        )
                                    )
                                ]
                         )
                       ]
                 -- ++ [ textLayout None
                 --         [ paddingBottom 10 ]
                 --         (List.map viewMessage model.session.messages)
                 --    , Input.text MessageInput
                 --         []
                 --         { label =
                 --             Input.placeholder
                 --                 { label = Input.labelLeft (el None [ verticalCenter ] empty)
                 --                 , text = "message"
                 --                 }
                 --         , onChange = UserInput
                 --         , options = []
                 --         , value = ""
                 --         }
                 --    , spacer 10
                 --    , button SessionListing [ paddingXY 10 5, onClick Send ] (text "Send")
                 --    ]
                )
            ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


viewSessionEntry : SessionId -> Element Styles variation Msg
viewSessionEntry sessionId =
    button Button
        [ paddingXY 10 5, spacingXY 0 10 ]
        (link (sessionPath sessionId) <| el None [] (text ("Session " ++ toString (sessionId))))


viewSessionButton : SessionId -> List SessionId -> Element Styles variation Msg
viewSessionButton sessionId selectedSessions =
    let
        style =
            case List.member sessionId selectedSessions of
                True ->
                    SelectedSessionButton

                False ->
                    SessionButton
    in
        button style
            [ paddingXY 10 5, onClick (ToggleSessionButton sessionId) ]
            (text (toString sessionId))


viewMessage : String -> Element Styles variation Msg
viewMessage msg =
    paragraph None [] [ text msg ]


viewLabels : Board -> Int -> List (Element Styles variation Msg)
viewLabels board tones =
    List.concatMap (\t -> viewTrackLabels t tones) board


viewTrackLabels : Track -> Int -> List (Element Styles variation Msg)
viewTrackLabels track tones =
    let
        labels =
            (List.indexedMap (,)) track.rowLabels
    in
        [ grid GridBlock
            []
            { columns = [ px 16 ]
            , rows = List.repeat tones (px 14)
            , cells = List.map viewLabelCell labels
            }
        , paragraph None [ paddingBottom 62 ] []
        ]


viewLabelCell : ( Int, String ) -> OnGrid (Element Styles variation Msg)
viewLabelCell label =
    cell
        { start = ( 0, Tuple.first label )
        , width = 1
        , height = 1
        , content = el RowLabel [ paddingTop 1 ] (text (Tuple.second label))
        }


viewBoard : Board -> ClientId -> Int -> Int -> List (Element Styles variation Msg)
viewBoard board clientId beats tones =
    List.concatMap (\t -> viewTrack t clientId beats tones) board


viewTrack : Track -> ClientId -> Int -> Int -> List (Element Styles variation Msg)
viewTrack track clientId beats tones =
    [ grid GridBlock
        [ spacing 1 ]
        { columns = List.repeat beats (px 99)
        , rows = List.repeat tones (px 13)
        , cells =
            viewGrid track clientId
        }
    , paragraph None
        [ paddingTop 8, paddingBottom 30 ]
        (case track.username of
            "" ->
                [ el InstrumentLabel [] (text track.instrument)
                , button Button
                    [ paddingXY 10 2, alignRight, onClick (RequestTrack track.trackId clientId) ]
                    (text "Request Track")
                ]

            _ ->
                [ el InstrumentLabel [] (text (track.username ++ " on " ++ track.instrument))
                , when
                    (clientId == track.clientId)
                    (button Button
                        [ paddingXY 10 2, alignRight, onClick (ReleaseTrack track.trackId "") ]
                        (text "Release Track")
                    )
                ]
        )
    ]


viewGrid : Track -> ClientId -> List (OnGrid (Element Styles variation Msg))
viewGrid track clientId =
    let
        rows =
            List.map (List.indexedMap (,)) track.grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\r -> viewRow track clientId r) tupleGrid


viewRow : Track -> ClientId -> ( Int, List ( Int, Int ) ) -> List (OnGrid (Element Styles variation Msg))
viewRow track clientId row =
    List.map (\c -> viewCell track clientId (Tuple.first row) c) (Tuple.second row)


viewCell : Track -> ClientId -> Int -> ( Int, Int ) -> OnGrid (Element Styles variation Msg)
viewCell track clientId row c =
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
                                case track.trackId of
                                    0 ->
                                        PlayOrange

                                    _ ->
                                        PlayPurple
                in
                    case clientId == track.clientId of
                        True ->
                            el act
                                [ onClick
                                    (UpdateBoard
                                        { trackId = track.trackId
                                        , column = col
                                        , row = row
                                        , action = (action + 1) % 2
                                        }
                                    )
                                ]
                                empty

                        False ->
                            el act [] empty
            }


newId : List SessionId -> SessionId
newId sessions =
    case List.head (List.reverse sessions) of
        Just head ->
            head + 1

        Nothing ->
            -1

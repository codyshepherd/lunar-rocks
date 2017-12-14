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
                [ navigation model.route model.sessionId
                , el None [ center, width (px 799) ] <|
                    column Main [ paddingTop 20, paddingBottom 50 ] (page model)
                ]


navigation : Route -> SessionId -> Element Styles variation Msg
navigation route sessionId =
    row Navigation [ center ] <|
        [ el None [ width (px 799) ] <|
            row Navigation
                [ spread, paddingXY 0 10, width (px 799) ]
                [ link sessionsPath <| el Logo [] (text "Lunar Rocks")
                , case route of
                    Home ->
                        row None
                            [ spacing 20, paddingBottom 5, alignBottom ]
                            [ link "https://github.com/codyshepherd/music" <|
                                el NavOption [ onClick Disconnect ] (text "⇑ Eject")
                            ]

                    SessionRoute id ->
                        row None
                            [ spacing 20, paddingBottom 5, alignBottom ]
                            [ link sessionsPath <| el NavOption [] (text "Sessions")
                            , link sessionsPath <|
                                el NavOption [ onClick (LeaveSession sessionId) ] (text "Leave Session")
                            ]

                    NotFoundRoute ->
                        row None
                            [ spacing 20, paddingBottom 5, alignBottom ]
                            [ link sessionsPath <| el NavOption [] (text "Sessions") ]
                ]
        ]


page : Model -> List (Element Styles variation Msg)
page model =
    case model.route of
        Home ->
            [ h3 SubHeading [ paddingBottom 20 ] (text "MAKE MUSIC ACROSS THE WEB")
            , paragraph Text
                [ paddingBottom 10 ]
                [ text
                    ("Lunar Rocks is a collaborative music making site. Lunar "
                        ++ "Rocks is in the early development, and we appreciate "
                        ++ "any feedback. "
                    )
                , (bold "Eject ")
                , text "above to visit the GitHub repo."
                ]
            , textLayout None
                [ spacingXY 25 20 ]
                (case model.username of
                    "" ->
                        [ paragraph Text [] [ text "Choose a nickname to get started." ]
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
                        [ paragraph Text
                            []
                            [ text
                                ("Greetings " ++ model.username ++ "! Select a session below or start a new one.")
                            ]
                        , paragraph None
                            []
                            (List.map (\s -> viewSessionEntry s model.sessionLists.clientSessions)
                                (List.filter (\id -> id /= 0) model.sessionLists.allSessions)
                            )
                        , paragraph None
                            []
                            [ button Button
                                [ paddingXY 10 5, onClick AddSession ]
                                (text "New Session")
                            ]
                        ]
                )
            , paragraph ServerMessage [ paddingTop 10 ] [ (text model.serverMessage) ]
            , paragraph ErrorMessage
                [ paddingTop 10 ]
                (List.map (\( _, error ) -> el None [] (text error)) model.validationErrors)
            ]
                ++ instructions

        SessionRoute id ->
            let
                session =
                    case List.head (List.filter (\s -> s.id == id) model.sessions) of
                        Just session ->
                            session

                        Nothing ->
                            emptySession 0

                otherSessions =
                    List.filter
                        (\cs -> cs /= id)
                        model.sessionLists.clientSessions
            in
                [ textLayout None
                    [ spacing 1 ]
                    ([ h3 SubHeading
                        [ paddingTop 20, paddingBottom 20 ]
                        (text ("SESSION " ++ toString (id)))
                     , row None
                        [ spacing 2 ]
                        [ column None [ spacing 1 ] (viewLabels session.board session.tones)
                        , column None
                            []
                            (viewBoard
                                model.sessionId
                                session.board
                                model.clientId
                                session.beats
                                session.tones
                                model.sessionLists.selectedSessions
                            )
                        ]
                     ]
                        ++ [ paragraph None
                                [ paddingBottom 10 ]
                                ((el SmallHeading [] (text "IN THIS SESSION:  "))
                                    :: (List.map viewMessage session.clients)
                                )
                           , textLayout None
                                [ paddingBottom 10 ]
                                (List.map viewMessage session.messages)
                           ]
                        ++ [ when ((List.length otherSessions) > 0)
                                (h3 SmallHeading
                                    [ paddingBottom 10 ]
                                    (text "YOUR SESSIONS")
                                )
                           , paragraph None
                                [ spacing 7 ]
                                (List.map
                                    (\cs ->
                                        viewSessionButton
                                            cs
                                            model.sessionLists.selectedSessions
                                    )
                                    otherSessions
                                )

                           -- TODO: Add Goto button once a sensible spot for it becomes clear
                           -- , spacer 10
                           -- , (let
                           --      selectedSessions =
                           --          model.sessionLists.selectedSessions
                           --    in
                           --      paragraph None
                           --          [ spacing 3 ]
                           --          [ when
                           --              ((List.length selectedSessions == 1)
                           --                  && (session.id /= Maybe.withDefault 0 (List.head selectedSessions))
                           --              )
                           --              (button
                           --                  Button
                           --                  [ paddingXY 10 2 ]
                           --                  (link
                           --                      (sessionPath (Maybe.withDefault 0 (List.head selectedSessions)))
                           --                   <|
                           --                      el None [] (text "Goto")
                           --                  )
                           --              )
                           --          ]
                           --   )
                           ]
                    )
                ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


instructions : List (Element Styles variation Msg)
instructions =
    [ h3 SubHeading [ paddingTop 10, paddingBottom 20 ] (text "HOW TO USE")
    , paragraph Text
        [ paddingBottom 10 ]
        [ text
            ("Music in Lunar Rocks is made in sessions. Each sesion has two tracks,"
                ++ " and you can claim one by selecting "
            )
        , bold "Request Track"
        , text
            (". Once you have a track, start making music by adding and removing "
                ++ "notes in the note grid. When you are happy with your creation, select "
            )
        , bold "Send "
        , text "and your music will be sent to the session."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ text "When you are done with a track, select "
        , bold "Release Track"
        , text " to free it. Your music will stay, and someone else can jump in and add their ideas."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ text
            ("If someone else is working on a track in your session, you will see and hear "
                ++ "the changes the changes they make. Collaborate with them! Make beautiful music!"
            )
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ text
            ("You can send your track to another session by claiming the same track in both "
                ++ "sessions, selectng the target session from "
            )
        , bold "Your Sessions"
        , text ", and then selecting "
        , bold "Broadcast"
        , text
            (". You can send to many sessions at once by selecting multiple "
                ++ "sessions before selecting "
            )
        , bold "Broadcast."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ text "Select "
        , bold "Leave Session"
        , text " when you are ready to move on. "
        , bold "Sessions"
        , text
            (" will bring you back to the list of sessions, but "
                ++ "you will stay active in the current session if you have a track open."
            )
        ]
    ]


viewSessionEntry : SessionId -> List SessionId -> Element Styles variation Msg
viewSessionEntry sessionId clientSessions =
    let
        style =
            if List.member sessionId clientSessions then
                ActiveButton
            else
                Button
    in
        el None
            [ spacing 7 ]
            (link (sessionPath sessionId) <|
                button style
                    [ paddingXY 10 5 ]
                    (text (toString (sessionId)))
            )


viewSessionButton : SessionId -> List SessionId -> Element Styles variation Msg
viewSessionButton sessionId selectedSessions =
    let
        style =
            if List.member sessionId selectedSessions then
                SelectedSessionButton
            else
                SessionButton
    in
        button style
            [ paddingXY 10 5, onClick (ToggleSessionButton sessionId) ]
            (text (toString sessionId))


viewMessage : String -> Element Styles variation Msg
viewMessage msg =
    el Text [ paddingLeft 5 ] (text msg)


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
        , paragraph None [ paddingBottom 72 ] []
        ]


viewLabelCell : ( Int, String ) -> OnGrid (Element Styles variation Msg)
viewLabelCell label =
    cell
        { start = ( 0, Tuple.first label )
        , width = 1
        , height = 1
        , content = el RowLabel [ paddingTop 1 ] (text (Tuple.second label))
        }


viewBoard : SessionId -> Board -> ClientId -> Int -> Int -> List SessionId -> List (Element Styles variation Msg)
viewBoard sessionId board clientId beats tones selectedSessions =
    List.concatMap (\t -> viewTrack sessionId t clientId beats tones selectedSessions) board


viewTrack : SessionId -> Track -> ClientId -> Int -> Int -> List SessionId -> List (Element Styles variation Msg)
viewTrack sessionId track clientId beats tones selectedSessions =
    [ grid GridBlock
        [ spacing 1 ]
        { columns = List.repeat beats (px 99)
        , rows = List.repeat tones (px 13)
        , cells =
            viewGrid sessionId track clientId
        }
    , paragraph None
        [ paddingTop 8, paddingBottom 30, spacing 5 ]
        (case track.username of
            "" ->
                [ el InstrumentLabel [] (text track.instrument)
                , button Button
                    [ paddingXY 10 2, alignRight, onClick (RequestTrack sessionId track.trackId clientId) ]
                    (text "Request Track")
                ]

            _ ->
                [ paragraph InstrumentLabel [ paddingBottom 13 ] [ (text (track.username ++ " on " ++ track.instrument)) ]
                , when
                    (clientId == track.clientId)
                    (button Button
                        [ paddingXY 10 2, alignRight, onClick (ReleaseTrack sessionId track.trackId "") ]
                        (text "Release Track")
                    )
                , when
                    (clientId == track.clientId)
                    (button Button
                        [ paddingXY 10 2, alignRight, onClick (Send sessionId) ]
                        (text "Send")
                    )
                , when
                    (((List.length selectedSessions == 1 && Maybe.withDefault 0 (List.head selectedSessions) /= sessionId)
                        || ((List.length selectedSessions) > 1)
                     )
                        && (clientId == track.clientId)
                    )
                    (button
                        Button
                        [ paddingXY 10 2, alignRight, onClick (Broadcast selectedSessions track) ]
                        (text "Broadcast")
                    )
                ]
        )
    ]


viewGrid : SessionId -> Track -> ClientId -> List (OnGrid (Element Styles variation Msg))
viewGrid sessionId track clientId =
    let
        rows =
            List.map (List.indexedMap (,)) track.grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\r -> viewRow sessionId track clientId r) tupleGrid


viewRow : SessionId -> Track -> ClientId -> ( Int, List ( Int, Int ) ) -> List (OnGrid (Element Styles variation Msg))
viewRow sessionId track clientId row =
    List.map (\c -> viewCell sessionId track clientId (Tuple.first row) c) (Tuple.second row)


viewCell : SessionId -> Track -> ClientId -> Int -> ( Int, Int ) -> OnGrid (Element Styles variation Msg)
viewCell sessionId track clientId row c =
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
                                        { sessionId = sessionId
                                        , trackId = track.trackId
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

module Views exposing (..)

import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input
import Html
import Models exposing (..)
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
                , bold "Eject "
                , text "above to visit the GitHub repo."
                ]
            , textLayout None
                [ spacingXY 25 20 ]
              <|
                case model.username of
                    "" ->
                        [ paragraph Text [] [ text "Choose a nickname to get started." ]
                        , row None
                            [ width (px 200), spacing 6 ]
                            [ Input.text MessageInput
                                [ paddingXY 2 3 ]
                                { label =
                                    Input.placeholder
                                        { label = Input.hiddenLabel "Nickname"
                                        , text = " Nickname..."
                                        }
                                , onChange = UserInput
                                , options = []
                                , value = ""
                                }
                            , button Button [ paddingXY 7 3, onClick SelectName ] (text "Submit")
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
            , when (model.username == "") <|
                paragraph None [ paddingTop 12, height (px 32) ] <|
                    [ el None [] <| nameHint model.input ]
            , paragraph ServerMessage [] [ (text model.serverMessage) ]
            , paragraph ErrorMessage
                []
              <|
                List.map (\( _, error ) -> el None [] (text error)) model.validationErrors
            , column None [] <| instructions
            ]

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
                  <|
                    [ h3 SubHeading
                        [ paddingTop 20, paddingBottom 20 ]
                        (text ("SESSION " ++ toString (id)))
                    , row None
                        [ spacing 2 ]
                        [ column None [ spacing 1 ] <| viewLabels session.board session.tones
                        , column None
                            []
                          <|
                            viewBoard
                                session.board
                                ( model.clientId, model.sessionId )
                                session.beats
                                session.tones
                                model.sessionLists.selectedSessions
                                ( model.selectInstrumentZero, model.selectInstrumentOne )
                        ]
                    ]
                        ++ [ paragraph None
                                [ paddingBottom 10 ]
                             <|
                                (el SmallHeading [] (text "IN THIS SESSION:  "))
                                    :: (List.map viewMessage session.clients)
                           , textLayout None [ paddingBottom 10 ] <| List.map viewMessage session.messages
                           ]
                        ++ [ when ((List.length otherSessions) > 0) <|
                                h3 SmallHeading
                                    [ paddingBottom 10 ]
                                    (text "YOUR SESSIONS")
                           , paragraph None
                                [ spacing 7 ]
                             <|
                                List.map
                                    (\cs ->
                                        viewSessionButton
                                            cs
                                            model.sessionLists.selectedSessions
                                    )
                                    otherSessions
                           ]
                ]

        NotFoundRoute ->
            [ textLayout None [] [ text "Not found" ] ]


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
        <|
            link (sessionPath sessionId) <|
                button style
                    [ paddingXY 10 5 ]
                    (text (toString (sessionId)))


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


viewBoard : Board -> ( ClientId, SessionId ) -> Int -> Int -> List SessionId -> InstrumentSelects -> List (Element Styles variation Msg)
viewBoard board ( clientId, sessionId ) beats tones selectedSessions instrumentSelects =
    List.concatMap
        (\t -> viewTrack t ( clientId, sessionId ) ( beats, tones ) selectedSessions instrumentSelects)
        board


viewTrack : Track -> ( ClientId, SessionId ) -> ( Int, Int ) -> List SessionId -> InstrumentSelects -> List (Element Styles variation Msg)
viewTrack track ( clientId, sessionId ) ( beats, tones ) selectedSessions ( selectZero, selectOne ) =
    let
        style =
            if track.clientId == clientId then
                GridBlockHeld
            else
                GridBlock
    in
        [ grid style
            [ spacing 1, noSelect ]
            { columns = List.repeat beats (px 99)
            , rows = List.repeat tones (px 13)
            , cells =
                viewGrid track ( clientId, sessionId )
            }
        , row None
            [ paddingTop 8, paddingBottom 40, spacing 5, spread ]
          <|
            case track.username of
                "" ->
                    [ column None [] <| [ el InstrumentLabel [] <| text track.instrument ]
                    , column None [] <|
                        [ button Button
                            [ paddingXY 10 2, alignRight, onClick (RequestTrack sessionId track.trackId clientId) ]
                          <|
                            text "Request Track"
                        ]
                    ]

                _ ->
                    [ column None [] <| [ el InstrumentLabel [] <| text (track.username ++ " on " ++ track.instrument) ]
                    , row None [ spacing 5 ] <|
                        [ when
                            (((List.length selectedSessions == 1 && Maybe.withDefault 0 (List.head selectedSessions) /= sessionId)
                                || ((List.length selectedSessions) > 1)
                             )
                                && (clientId == track.clientId)
                            )
                          <|
                            button
                                Button
                                [ paddingXY 10 2, alignRight, onClick (Broadcast selectedSessions track) ]
                                (text "Broadcast")
                        , when
                            (clientId == track.clientId)
                          <|
                            button Button
                                [ paddingXY 10 2, alignRight, onClick (SendSession sessionId) ]
                                (text "Send")
                        , when
                            (clientId == track.clientId)
                          <|
                            if track.trackId == 0 then
                                selectInstrument selectZero sessionId track.trackId
                            else
                                selectInstrument selectOne sessionId track.trackId
                        , when
                            (clientId == track.clientId)
                          <|
                            button Button
                                [ paddingXY 10 2, alignRight, onClick (ReleaseTrack sessionId track.trackId "") ]
                                (text "Release Track")
                        ]
                    ]
        ]


instructions : List (Element Styles variation Msg)
instructions =
    [ h3 SubHeading [ paddingTop 15, paddingBottom 20 ] (text "REFERENCE GUIDE")
    , h4 SmallHeading [ paddingBottom 10 ] (text "Note Grid")
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Add a note "
        , text "by clicking and dragging to the desired note length."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Extend a note "
        , text "by clicking and dragging on the far right portion of an existing note."
        ]
    , paragraph Text
        [ paddingBottom 20 ]
        [ bold "Remove a note "
        , text "by clicking on it."
        ]
    , h4 SmallHeading [ paddingBottom 10 ] (text "Track Controls")
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Request Track: "
        , text "Claim a free track."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Release Track: "
        , text "Release a track you control."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Change Instrument: "
        , text "Select an instrument."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Send: "
        , text "Sends any changes you have made to a track. Your collaborators will see and hear them!"
        ]
    , paragraph Text
        [ paddingBottom 20 ]
        [ bold "Broadcast: "
        , text <|
            "Send a track to another session. "
                ++ "Select the target session or sessions in the Your Sessions area below the tracks. "
                ++ "Note that you must control the track in both sessions. "
        ]
    , h4 SmallHeading [ paddingBottom 10 ] (text "Session Navigation")
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Sessions: "
        , text "Go to the home page, but stay active on any tracks you control."
        ]
    , paragraph Text
        [ paddingBottom 10 ]
        [ bold "Leave Session: "
        , text "Go to the home page, and release any tracks you control."
        ]
    ]


nameHint : String -> Element Styles variation msg
nameHint input =
    if String.length input == 0 then
        text ""
    else if String.length input < 3 then
        el ErrorMessage [] (text "🗙 More letters please")
    else if String.length input > 20 then
        el ErrorMessage [] (text "🗙 Too long...")
    else
        el SuccessMessage [] (text "✔ Nice one!")



-- GRID


viewGrid : Track -> ( ClientId, SessionId ) -> List (OnGrid (Element Styles variation Msg))
viewGrid track ( clientId, sessionId ) =
    let
        rows =
            List.map (List.indexedMap (,)) track.grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\row -> viewRow row track ( clientId, sessionId )) tupleGrid


viewRow : ( Int, List ( Int, Int ) ) -> Track -> ( ClientId, SessionId ) -> List (OnGrid (Element Styles variation Msg))
viewRow ( row, cols ) track ids =
    case cols of
        c :: d :: cs ->
            case Tuple.second c of
                0 ->
                    viewCell ( row, c ) track ids :: viewRow ( row, (d :: cs) ) track ids

                _ ->
                    if (Tuple.second d > Tuple.second c) then
                        viewRow ( row, (d :: cs) ) track ids
                    else
                        viewCell ( row, c ) track ids :: viewRow ( row, (d :: cs) ) track ids

        c :: cs ->
            viewCell ( row, c ) track ids :: viewRow ( row, cs ) track ids

        [] ->
            []


viewCell : ( Int, ( Int, Int ) ) -> Track -> ( ClientId, SessionId ) -> OnGrid (Element Styles variation Msg)
viewCell ( row, ( col, action ) ) track ( clientId, sessionId ) =
    let
        colStart =
            case action of
                0 ->
                    col

                _ ->
                    -- backtrack to note start
                    ((col - action) + 1)
    in
        cell
            { start = ( colStart, row )
            , width =
                case action of
                    0 ->
                        1

                    _ ->
                        action
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
                                [ onMouseDown <|
                                    SelectCell
                                        { sessionId = sessionId
                                        , trackId = track.trackId
                                        , row = row
                                        , column = colStart
                                        , length = (col - colStart + 1)
                                        , action = action
                                        }
                                , onMouseUp <|
                                    UpdateGrid
                                        { sessionId = sessionId
                                        , trackId = track.trackId
                                        , row = row
                                        , column = colStart
                                        , length = (col - colStart + 1)
                                        , action = action
                                        }
                                ]
                            <|
                                case action of
                                    0 ->
                                        empty

                                    _ ->
                                        if colStart + action == 8 then
                                            empty
                                        else
                                            el ExtendHandle
                                                [ alignRight, minHeight (px 13), minWidth (px 10) ]
                                                empty

                        False ->
                            el act [] empty
            }



-- SELECT_INSTRUMENT


selectInstrument : Input.SelectWith Instrument Msg -> SessionId -> TrackId -> Element Styles variation Msg
selectInstrument select sessionId trackId =
    el InstrumentField [] <|
        Input.select Field
            [ paddingXY 10 2, alignRight ]
            { label = Input.placeholder { text = "Change Instrument ", label = Input.hiddenLabel "Change Instrument" }
            , with = select
            , options = []
            , max = 4
            , menu =
                Input.menu SubMenu
                    []
                    [ Input.styledSelectChoice (Guitar ( sessionId, trackId )) <| (\state -> instrumentChoice state "Guitar ")
                    , Input.styledSelectChoice (Marimba ( sessionId, trackId )) <| (\state -> instrumentChoice state "Marimba ")
                    , Input.styledSelectChoice (Piano ( sessionId, trackId )) <| (\state -> instrumentChoice state "Piano ")
                    , Input.styledSelectChoice (Xylophone ( sessionId, trackId )) <| (\state -> instrumentChoice state "Xylophone ")
                    ]
            }


instrumentChoice : Input.ChoiceState -> String -> Element Styles variation Msg
instrumentChoice state instrument =
    let
        style =
            case state of
                Input.Selected ->
                    MenuChoiceSelected

                Input.Focused ->
                    MenuChoiceFocused

                Input.Idle ->
                    MenuChoiceIdle

                Input.SelectedInBox ->
                    MenuChoiceSelectedInBox
    in
        el style [] <| text instrument

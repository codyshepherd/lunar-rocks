module ServerUpdate exposing (serverUpdateModel, serverCommand)

import Decode exposing (..)
import Models exposing (..)
import Ports exposing (sendScore)
import Score exposing (readGrid)


serverCommand : Maybe ServerMessage -> Model -> Cmd msg
serverCommand serverMessage model =
    case serverMessage of
        Just sm ->
            case sm.messageId of
                100 ->
                    case sm.payload of
                        SessionMessage su ->
                            let
                                session =
                                    Maybe.withDefault
                                        (emptySession su.sessionId)
                                        (List.head (List.filter (\s -> s.id == su.sessionId) model.sessions))
                            in
                                sendScore session.score

                        _ ->
                            Debug.log "100: Payload mismatch" Cmd.none

                _ ->
                    Cmd.none

        Nothing ->
            Cmd.none


serverUpdateModel : Maybe ServerMessage -> Model -> Model
serverUpdateModel serverMessage model =
    case serverMessage of
        Just sm ->
            case sm.messageId of
                100 ->
                    serverUpdateSession sm model

                102 ->
                    serverNewSession sm model

                105 ->
                    case sm.payload of
                        SessionIds ids ->
                            let
                                sessionLists =
                                    model.sessionLists

                                newSessions =
                                    List.sort ids

                                newSessionsLists =
                                    { sessionLists | allSessions = newSessions }
                            in
                                { model
                                    | sessionLists = newSessionsLists
                                }

                        _ ->
                            Debug.log "105: Payload mismatch" model

                107 ->
                    case sm.payload of
                        DisconnectMessage msg ->
                            { model
                                | sessionId = 0
                                , serverMessage = "The server disconnected you."
                            }

                        _ ->
                            Debug.log "107: Payload mismatch" model

                111 ->
                    serverUpdateTrackStatus sm model

                113 ->
                    case sm.payload of
                        ClientInit id sessionList ->
                            let
                                sessionLists =
                                    model.sessionLists

                                newSessions =
                                    List.sort sessionList

                                newSessionsLists =
                                    { sessionLists | allSessions = newSessions }
                            in
                                { model | clientId = id, sessionLists = newSessionsLists, input = "" }

                        _ ->
                            Debug.log "113: Payload mismatch" model

                114 ->
                    case sm.payload of
                        Error msg ->
                            Debug.log ("Error: " ++ msg) model

                        _ ->
                            Debug.log "114: Payload mismatch" model

                _ ->
                    Debug.log "Bad messageId" model

        Nothing ->
            Debug.log "Decode failure" model


serverUpdateSession : ServerMessage -> Model -> Model
serverUpdateSession serverMessage model =
    case serverMessage.payload of
        SessionMessage su ->
            let
                session =
                    Maybe.withDefault (emptySession 0)
                        (List.head
                            (List.filter (\s -> s.id == su.sessionId) model.sessions)
                        )

                board =
                    session.board

                newBoard =
                    serverUpdateBoard board su.boardUpdate model.clientId model.sessionId su.sessionId

                newScore =
                    List.concatMap
                        (\t -> serverUpdateScore t board session.tones model.clientId model.sessionId su.sessionId)
                        su.boardUpdate

                newSession =
                    { session
                        | board = newBoard
                        , clients = su.clientsUpdate
                        , tempo = su.tempoUpdate
                        , score = newScore
                    }

                newSessions =
                    newSession
                        :: (List.filter (\s -> s.id /= su.sessionId) model.sessions)
            in
                { model | sessions = newSessions }

        _ ->
            Debug.log ("100: Payload mismatch") model


serverNewSession : ServerMessage -> Model -> Model
serverNewSession serverMessage model =
    case serverMessage.payload of
        SessionMessage su ->
            let
                session =
                    emptySession su.sessionId

                board =
                    session.board

                newBoard =
                    serverUpdateBoard board su.boardUpdate model.clientId model.sessionId su.sessionId

                newSession =
                    { session
                        | board = newBoard
                        , clients = su.clientsUpdate
                        , tempo = su.tempoUpdate
                    }

                newSessions =
                    newSession :: model.sessions

                sessionLists =
                    model.sessionLists

                newSessionsLists =
                    { sessionLists | allSessions = List.sort (su.sessionId :: sessionLists.allSessions) }
            in
                { model | sessions = newSessions, sessionLists = newSessionsLists }

        _ ->
            Debug.log ((toString (serverMessage.messageId)) ++ ": Payload mismatch") model


serverUpdateBoard : Board -> List TrackUpdate -> ClientId -> SessionId -> SessionId -> Board
serverUpdateBoard board boardUpdate clientId sessionId suId =
    List.map (\t -> serverUpdateTrack t boardUpdate clientId sessionId suId) board


serverUpdateTrack : Track -> List TrackUpdate -> ClientId -> SessionId -> SessionId -> Track
serverUpdateTrack track boardUpdate clientId sessionId suId =
    let
        trackUpdate =
            Maybe.withDefault
                { trackId = track.trackId
                , clientId = track.clientId
                , username = track.username
                , grid = track.grid
                }
                (List.head
                    (List.filter (\tu -> tu.trackId == track.trackId) boardUpdate)
                )
    in
        if track.clientId == clientId && suId == sessionId then
            track
        else
            { track | grid = trackUpdate.grid, clientId = trackUpdate.clientId, username = trackUpdate.username }


serverUpdateScore : TrackUpdate -> Board -> Int -> ClientId -> SessionId -> SessionId -> Score
serverUpdateScore tu board tones clientId sessionId suId =
    let
        track =
            List.head (List.filter (\t -> t.trackId == tu.trackId) board)

        instrument =
            case track of
                Just t ->
                    t.instrument

                Nothing ->
                    "Marimba"
    in
        case sessionId of
            0 ->
                []

            _ ->
                if tu.clientId == clientId && suId == sessionId then
                    case track of
                        Just t ->
                            readGrid t.grid t.trackId t.instrument tones

                        Nothing ->
                            []
                else
                    -- TODO: change to tu.instrument when server tracks instrument changes
                    readGrid tu.grid tu.trackId instrument tones


serverUpdateTrackStatus : ServerMessage -> Model -> Model
serverUpdateTrackStatus serverMessage model =
    case serverMessage.payload of
        TrackRequestResponse status sessionId trackId ->
            if status then
                let
                    session =
                        Maybe.withDefault
                            (emptySession sessionId)
                            (List.head (List.filter (\s -> s.id == sessionId) model.sessions))

                    newTrack =
                        updateTrackUser trackId model.clientId model.username session.board

                    newBoard =
                        List.take trackId session.board
                            ++ newTrack
                            :: List.drop (trackId + 1) session.board

                    newSession =
                        { session | board = newBoard }

                    newSessions =
                        newSession :: model.sessions

                    sessionLists =
                        model.sessionLists

                    newClientSessions =
                        case List.member session.id sessionLists.clientSessions of
                            True ->
                                sessionLists.clientSessions

                            False ->
                                List.sort (session.id :: sessionLists.clientSessions)

                    newSessionLists =
                        { sessionLists | clientSessions = newClientSessions }
                in
                    { model | sessions = newSessions, sessionLists = newSessionLists }
            else
                model

        _ ->
            Debug.log "111: Payload mismatch" model


updateTrackUser : TrackId -> ClientId -> String -> Board -> Track
updateTrackUser trackId clientId username board =
    let
        track =
            List.head (List.filter (\t -> t.trackId == trackId) board)
    in
        case track of
            Just t ->
                { t | clientId = clientId, username = username }

            Nothing ->
                Track -1 "" "" "404s" [] []

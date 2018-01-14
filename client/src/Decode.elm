module Decode exposing (..)

import Json.Decode exposing (Decoder, string, int, bool, list, field, map, andThen, decodeString)
import Json.Decode.Pipeline exposing (custom, decode, required, optional)


type alias ServerMessage =
    { sourceId : String
    , messageId : Int
    , payload : Payload
    }


type Payload
    = SessionMessage SessionUpdate
    | ClientInit String (List Int)
    | DisconnectMessage String
    | Error String
    | SessionIds (List Int)
    | TrackRequestResponse Bool Int Int


type alias SessionUpdate =
    { sessionId : Int
    , clientsUpdate : List String
    , tempoUpdate : Int
    , boardUpdate : List TrackUpdate
    }


type alias TrackUpdate =
    { trackId : Int
    , clientId : String
    , username : String
    , instrument : String
    , grid : List (List Int)
    }


type alias TrackStatus =
    { status : Bool
    , sessionId : Int
    , trackId : Int
    }


decodeServerMessage : Decoder ServerMessage
decodeServerMessage =
    decode ServerMessage
        |> required "sourceID" string
        |> required "messageID" int
        |> custom (field "messageID" int |> andThen decodePayload)


decodePayload : Int -> Decoder Payload
decodePayload messageId =
    let
        payload =
            field "payload"
    in
        case messageId of
            100 ->
                payload decodeSession

            102 ->
                payload decodeSession

            105 ->
                payload decodeSessionIds

            107 ->
                payload decodeDisconnect

            111 ->
                payload decodeTrackStatus

            113 ->
                payload decodeClientInit

            114 ->
                payload decodeError

            _ ->
                payload decodeClientInit


decodeSession : Decoder Payload
decodeSession =
    decode SessionMessage
        |> required "session" decodeSessionMessage


decodeSessionMessage : Decoder SessionUpdate
decodeSessionMessage =
    decode SessionUpdate
        |> required "sessionID" int
        |> required "clients" (list string)
        |> required "tempo" int
        |> required "board" (list decodeTrackUpdate)


decodeTrackUpdate : Decoder TrackUpdate
decodeTrackUpdate =
    decode TrackUpdate
        |> required "trackID" int
        |> required "clientID" string
        |> required "nickname" string
        |> required "instrument" string
        |> required "grid" (list (list int))


decodeSessionIds : Decoder Payload
decodeSessionIds =
    decode SessionIds
        |> required "sessionIDs" (list int)


decodeDisconnect : Decoder Payload
decodeDisconnect =
    decode DisconnectMessage
        |> optional "error" string "The server disconnected."


decodeError : Decoder Payload
decodeError =
    decode Error
        |> required "error" string


decodeTrackStatus : Decoder Payload
decodeTrackStatus =
    decode TrackRequestResponse
        |> required "status" bool
        |> required "sessionID" int
        |> required "trackID" int


decodeClientInit : Decoder Payload
decodeClientInit =
    decode ClientInit
        |> required "clientID" string
        |> required "sessionIDs" (list int)

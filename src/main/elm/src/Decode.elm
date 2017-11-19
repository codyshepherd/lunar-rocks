module Decode exposing (..)

import Json.Decode exposing (Decoder, string, int, bool, list, field, map, andThen, decodeString)
import Json.Decode.Pipeline exposing (custom, decode, required, optional)


type alias ServerMessage =
    { sourceId : String
    , messageId : Int
    , payload : Payload
    }


type Payload
    = SessionMessage Int (List String) Int (List TrackMessage)
    | ClientId String
    | DisconnectMessage String
    | Error String
    | SessionIds (List Int)



-- | Status Bool


type alias TrackMessage =
    { trackId : Int
    , clientId : String
    , grid : List (List Int)
    }


decodeServerMessage : Decoder ServerMessage
decodeServerMessage =
    decode ServerMessage
        |> required "sourceID" string
        |> required "messageID" int
        |> custom (field "messageID" int |> andThen decodePayload)


decodePayload : Int -> Decoder Payload
decodePayload messageId =
    case messageId of
        100 ->
            field "payload" decodeSession

        102 ->
            field "payload" decodeSession

        105 ->
            field "payload" decodeSessionIds

        107 ->
            field "payload" decodeDisconnect

        -- 111 ->
        --     decodeStatus
        113 ->
            field "payload" decodeClientId

        114 ->
            field "payload" decodeError

        _ ->
            field "payload" decodeClientId


decodeSession : Decoder Payload
decodeSession =
    decode SessionMessage
        |> required "sessionId" int
        |> required "clients" (list string)
        |> required "tempo" int
        |> required "board" (list decodeTrackMessage)


decodeTrackMessage : Decoder TrackMessage
decodeTrackMessage =
    decode TrackMessage
        |> required "trackID" int
        |> required "clientID" string
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



-- decodeStatus : Decoder
-- decodeStatus =
--     decode Status
--         |> required "status" bool


decodeClientId : Decoder Payload
decodeClientId =
    decode ClientId
        |> required "clientID" string

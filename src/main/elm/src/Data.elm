module Data exposing (..)

import Json.Encode exposing (encode, Value, string, int, float, bool, list, object)


encodeMessage : String -> Int -> Value -> String
encodeMessage clientId messageId payload =
    let
        message =
            object
                [ ( "sourceId", string clientId )
                , ( "messageId", int messageId )
                , ( "payload", payload )
                ]
    in
        encode 0 message


encodeNickname : String -> Value
encodeNickname nickname =
    object [ ( "nickname", string nickname ) ]


encodeError : String -> Value
encodeError error =
    object [ ( "error", string error ) ]

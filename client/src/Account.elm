module Account exposing (Account, avatar, decoder, email, username)

import Avatar exposing (Avatar)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)



-- TYPES


type alias Account =
    { username : String
    , email : String
    , avatar : Avatar
    }



-- DECODE


decoder : Decoder Account
decoder =
    Decode.succeed Account
        |> required "username" Decode.string
        |> required "email" Decode.string
        |> required "avatar" Avatar.decoder



-- TRANSFORM


username : Account -> String
username account =
    account.username


email : Account -> String
email account =
    account.email


avatar : Account -> Avatar
avatar account =
    account.avatar

module Account exposing (Account, decoder, email, username)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)



-- TYPES


type alias Account =
    { username : String
    , email : String
    }



-- DECODE


decoder : Decoder Account
decoder =
    Decode.succeed Account
        |> required "username" Decode.string
        |> required "email" Decode.string



-- TRANSFORM


username : Account -> String
username account =
    account.username


email : Account -> String
email account =
    account.email

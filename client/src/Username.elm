module Username exposing (Username, decoder, encode, makeUsername, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


{-| User is adapted from the elm-spa-example Viewer: <https://github.com/rtfeldman/elm-spa-example/blob/master/src/Username.elm>
-}



-- TYPES


type Username
    = Username String



-- CREATE


decoder : Decoder Username
decoder =
    Decode.map Username Decode.string


makeUsername : String -> Username
makeUsername name =
    Username name



-- TRANSFORM


encode : Username -> Value
encode (Username username) =
    Encode.string username


toString : Username -> String
toString (Username username) =
    username

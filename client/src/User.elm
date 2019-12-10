module User exposing (User(..), cred, decoder, minPasswordChars, username)

{-| User is adapted from the elm-spa-example: <https://github.com/rtfeldman/elm-spa-example/blob/master/src/Viewer.elm>

User wraps Cred, and we can't have a logged in user without credentials. Cred
stores username which is accessed through this module in the rest of the
application.

-}

import Api exposing (Cred)
import Json.Decode as Decode exposing (Decoder)
import Username exposing (Username)



-- TYPES


type User
    = User Cred



-- INFO


cred : User -> Cred
cred (User val) =
    val


username : User -> Username
username (User val) =
    Api.username val


minPasswordChars : Int
minPasswordChars =
    16



-- SERIALIZATION


decoder : Decoder (Cred -> User)
decoder =
    Decode.succeed User

module User exposing (User(..), account, cred, decoder, minPasswordChars)

{-| User is adapted from the elm-spa-example: <https://github.com/rtfeldman/elm-spa-example/blob/master/src/Viewer.elm>

User wraps Cred, and we can't have a logged in user without credentials. Cred
stores username which is accessed through this module in the rest of the
application.

-}

import Account exposing (Account)
import Api exposing (Cred)
import Json.Decode as Decode exposing (Decoder)



-- TYPES


type User
    = User Cred



-- INFO


cred : User -> Cred
cred (User val) =
    val


account : User -> Account
account (User val) =
    Api.account val


minPasswordChars : Int
minPasswordChars =
    16



-- SERIALIZATION


decoder : Decoder (Cred -> User)
decoder =
    Decode.succeed User

module User exposing (User(..), account, cred, decoder, minPasswordChars, profile)

{- User wraps Cred. We can't have a logged in user without credentials.
   Cred stores username which is accessed through this module in the rest of the
   application.
-}

import Account exposing (Account)
import Api exposing (Cred)
import Json.Decode as Decode exposing (Decoder)
import Profile exposing (Profile)



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


profile : User -> Profile
profile (User val) =
    Api.profile val


minPasswordChars : Int
minPasswordChars =
    16



-- SERIALIZATION


decoder : Decoder (Cred -> User)
decoder =
    Decode.succeed User

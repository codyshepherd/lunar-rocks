module Profile exposing (Profile, avatar, bio, decoder, displayName, location, website)

import Avatar exposing (Avatar)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)



-- TYPES


type alias Profile =
    { avatar : Avatar
    , displayName : String
    , bio : String
    , location : String
    , website : String
    }



-- DECODE


decoder : Decoder Profile
decoder =
    Decode.succeed Profile
        |> required "avatar" Avatar.decoder
        |> optional "displayName" Decode.string ""
        |> optional "bio" Decode.string ""
        |> optional "location" Decode.string ""
        |> optional "website" Decode.string ""



-- TRANSFORM


avatar : Profile -> Avatar
avatar profile =
    profile.avatar


displayName : Profile -> String
displayName profile =
    profile.displayName


bio : Profile -> String
bio profile =
    profile.bio


location : Profile -> String
location profile =
    profile.location


website : Profile -> String
website profile =
    profile.website

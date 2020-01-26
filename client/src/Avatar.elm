module Avatar exposing (Avatar, imageMeta, noAvatar)

import Asset exposing (ImageMeta)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)



-- TYPES


type Avatar
    = Avatar (Maybe ImageMeta)



-- CREATE
-- decoder : Decoder Avatar
-- decoder =
--     Decode.map Avatar (Decode.nullable Decode.string)


noAvatar : Avatar
noAvatar =
    Avatar Nothing



-- TRANSFORM
-- encode : Avatar -> Value
-- encode (Avatar maybeUrl) =
--     case maybeUrl of
--         Just url ->
--             Encode.string url
--         Nothing ->
--             Encode.null


imageMeta : Avatar -> ImageMeta
imageMeta (Avatar maybeImageMeta) =
    case maybeImageMeta of
        Nothing ->
            Asset.imageMeta Asset.defaultAvatar

        Just meta ->
            if meta.src == "" then
                Asset.imageMeta Asset.defaultAvatar

            else
                meta



-- toMaybeString : Avatar -> Maybe String
-- toMaybeString (Avatar maybeUrl) =
--     maybeUrl

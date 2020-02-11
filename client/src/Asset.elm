module Asset exposing (Image, ImageMeta, defaultAvatar, imageMeta, imageMetaDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (hardcoded, required)


type Image
    = Image ImageMeta


type alias ImageMeta =
    { src : String
    , description : String
    }



-- IMAGES


defaultAvatar : Image
defaultAvatar =
    image
        { filename = "triangle.svg"
        , description = "Default avatar"
        }


image : { filename : String, description : String } -> Image
image { filename, description } =
    Image
        { src = "/assets/" ++ filename
        , description = description
        }


remoteImage : { url : String, description : String } -> Image
remoteImage { url, description } =
    Image
        { src = url
        , description = description
        }



-- CREATE IMAGES


imageMetaDecoder : Decoder ImageMeta
imageMetaDecoder =
    Decode.succeed ImageMeta
        |> required "url" Decode.string
        |> required "description" Decode.string



-- USING IMAGES


imageMeta : Image -> ImageMeta
imageMeta (Image meta) =
    { src = meta.src, description = meta.description }

module Asset exposing (Image, ImageMeta, defaultAvatar, imageMeta)


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
        { filename = "sine.svg"
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



-- USING IMAGES


imageMeta : Image -> ImageMeta
imageMeta (Image meta) =
    { src = meta.src, description = meta.description }

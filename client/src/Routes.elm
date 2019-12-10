module Routes exposing (Route(..), fromUrl, routeParser)

import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, s, string, top)


type Route
    = NotFound
    | Confirm
    | Home
    | Login
    | Profile String
    | Register
    | MusicSession String String


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Confirm (s "confirm")
        , map Home top
        , map Login (s "login")
        , map Register (s "register")
        , map MusicSession (string </> string)
        , map Profile string
        ]


fromUrl : Url.Url -> Route
fromUrl url =
    Maybe.withDefault NotFound (Url.Parser.parse routeParser url)

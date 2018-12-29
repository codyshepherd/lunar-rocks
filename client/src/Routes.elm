module Routes exposing (Route(..), fromUrl, routeParser)

import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, top)


type Route
    = NotFound
    | Home
    | Login
    | Profile
    | Register
    | Session Int


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Home top
        , map Login (s "login")
        , map Profile (s "profile")
        , map Register (s "register")
        , map Session (s "session" </> int)
        ]


fromUrl : Url.Url -> Route
fromUrl url =
    Maybe.withDefault NotFound (Url.Parser.parse routeParser url)

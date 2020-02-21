module Routes exposing (Route(..), fromUrl, routeParser)

import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, s, string, top)


type Route
    = NotFound
    | Confirm
    | ForgotPassword
    | Home
    | Login
    | Logout
    | Profile String
    | ProfileSettings
    | Register
    | ResetPassword
    | AccountSettings
    | MusicSession String String


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Confirm (s "confirm")
        , map ForgotPassword (s "forgot-password")
        , map Home top
        , map Login (s "login")
        , map Logout (s "logout")
        , map Register (s "register")
        , map ResetPassword (s "reset-password")
        , map ProfileSettings (s "settings" </> s "profile")
        , map AccountSettings (s "settings" </> s "account")
        , map MusicSession (string </> string)
        , map Profile string
        ]


fromUrl : Url.Url -> Route
fromUrl url =
    Maybe.withDefault NotFound (Url.Parser.parse routeParser url)

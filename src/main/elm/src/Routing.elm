module Routing exposing (..)

import Navigation exposing (Location)
import Models exposing (SessionId, Route(..))
import UrlParser exposing (..)


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map Home top
        , map SessionRoute (s "sessions" </> string)
        , map Home (s "sessions")
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


sessionsPath : String
sessionsPath =
    "#sessions"


sessionPath : SessionId -> String
sessionPath id =
    "#sessions/" ++ id

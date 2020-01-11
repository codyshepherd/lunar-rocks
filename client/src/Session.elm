module Session exposing (Session(..), changes, cred, fromUser, navKey, user)

import Api exposing (Cred)
import Browser.Navigation as Nav
import User exposing (User)



-- TYPES


type Session
    = LoggedIn Nav.Key User
    | Anonymous Nav.Key



-- INFO


user : Session -> Maybe User
user session =
    case session of
        LoggedIn _ val ->
            Just val

        Anonymous _ ->
            Nothing


cred : Session -> Maybe Cred
cred session =
    case session of
        LoggedIn _ val ->
            Just (User.cred val)

        Anonymous _ ->
            Nothing


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        Anonymous key ->
            key



-- CHANGES


{-| We subscribe to credential changes in localStorage here and update the session when user logs in or logs out.
-}
changes : (Session -> msg) -> Nav.Key -> Sub msg
changes toMsg key =
    Api.userChanges (\maybeUser -> toMsg (fromUser key maybeUser)) User.decoder


fromUser : Nav.Key -> Maybe User -> Session
fromUser key maybeUser =
    case maybeUser of
        Just viewerVal ->
            LoggedIn key viewerVal

        Nothing ->
            Anonymous key

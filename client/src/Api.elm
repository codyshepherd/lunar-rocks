port module Api exposing (Cred, Flags, application, fakeLogin, fakeRegister, login, logout, register, storeCredWith, userChanges, username)

import Browser
import Browser.Navigation as Nav
import Http exposing (Body)
import Json.Decode as Decode exposing (Decoder, Value, decodeString, field, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Url exposing (Url)
import Url.Builder exposing (QueryParameter)
import Username exposing (Username)



{- This module is adapted from the elm-spa-example: https://github.com/rtfeldman/elm-spa-example/blob/master/src/Api.elm -}


type alias Flags =
    String



-- CRED


{-| Authentication credentials

We define Cred to limit the visibility of the token to this module. Username is
exposed and can be used in other modules.

-}
type Cred
    = Cred Username String


username : Cred -> Username
username (Cred uname _) =
    uname


credHeader : Cred -> Http.Header
credHeader (Cred _ str) =
    Http.header "authorization" ("Token " ++ str)


credDecoder : Decoder Cred
credDecoder =
    Decode.succeed Cred
        |> required "username" Username.decoder
        |> required "token" Decode.string



-- PERSISTENCE


{-| onAuthStoreChange listens for changes to user credentials in localStorage as
reported by JavaScript. This can happen when a user signs up, logs in, or logs
out.

storeAuth is a port to JavaScript that stores credentials.

storeCredWith stores user credentials sent in a response from the server on
signing up or logging in.

logout removes credentials when a user logs out in the client application.

-}
port onAuthStoreChange : (Value -> msg) -> Sub msg


userChanges : (Maybe user -> msg) -> Decoder (Cred -> user) -> Sub msg
userChanges toMsg decoder =
    onAuthStoreChange (\value -> toMsg (decodeFromChange decoder value))


decodeFromChange : Decoder (Cred -> user) -> Value -> Maybe user
decodeFromChange userDecoder val =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    Decode.decodeValue (storageDecoder userDecoder) val
        |> Result.toMaybe


storeCredWith : Cred -> Cmd msg
storeCredWith (Cred uname token) =
    let
        json =
            Encode.object
                [ ( "user"
                  , Encode.object
                        [ ( "username", Username.encode uname )
                        , ( "token", Encode.string token )
                        ]
                  )
                ]
    in
    storeAuth (Just json)


logout : Cmd msg
logout =
    storeAuth Nothing


port storeAuth : Maybe Value -> Cmd msg



-- APPLICATION


{-| application initializes with credentials if they exist in localStorage

We call this in Main and get most of the initialization from there, but doing
this here restricts credential access to this module.

-}
application :
    Decoder (Cred -> user)
    ->
        { init : Maybe user -> Url -> Nav.Key -> ( model, Cmd msg )
        , onUrlChange : Url -> msg
        , onUrlRequest : Browser.UrlRequest -> msg
        , subscriptions : model -> Sub msg
        , update : msg -> model -> ( model, Cmd msg )
        , view : model -> Browser.Document msg
        }
    -> Program Value model msg
application userDecoder config =
    let
        init flags url navKey =
            let
                maybeUser =
                    Decode.decodeValue Decode.string flags
                        |> Result.andThen (Decode.decodeString (storageDecoder userDecoder))
                        |> Result.toMaybe
            in
            config.init maybeUser url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }


storageDecoder : Decoder (Cred -> user) -> Decoder user
storageDecoder userDecoder =
    Decode.field "user" (decoderFromCred userDecoder)


decoderFromCred : Decoder (Cred -> a) -> Decoder a
decoderFromCred decoder =
    Decode.map2 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder



-- HTTP


{-| Custom Http requests that include credentials when appropriate.

This section can be improved by adding an Endpoint module to clean up the wayn
that Urls are handled. We will definitely need to do this when we add more
services since the current implementation hardcodes a single root Url.

-}
get : String -> Maybe Cred -> Decoder a -> Http.Request a
get url maybeCred decoder =
    Http.request
        { method = "GET"
        , url = url
        , expect = Http.expectJson decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = Http.emptyBody
        , timeout = Nothing
        , withCredentials = False
        }


post : String -> Maybe Cred -> Body -> Decoder a -> Http.Request a
post url maybeCred body decoder =
    Http.request
        { method = "POST"
        , url = url
        , expect = Http.expectJson decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , withCredentials = False -- check if needed for CORS credential insistence
        }


toUrl : List String -> List QueryParameter -> String
toUrl paths queryParams =
    Url.Builder.crossOrigin "http://localhost:9000" paths queryParams


login : Http.Body -> Decoder (Cred -> a) -> Http.Request a
login body decoder =
    post (toUrl [ "login" ] []) Nothing body (Decode.field "user" (decoderFromCred decoder))


register : Http.Body -> Decoder (Cred -> a) -> Http.Request a
register body decoder =
    post (toUrl [ "register" ] []) Nothing body (Decode.field "user" (decoderFromCred decoder))


{-| Fake login and register for testing without a server.

TODO: Remove these when server integration is completed.

-}
fakeLogin : String -> String -> Cmd msg
fakeLogin uname password =
    storeCredWith (Cred (Username.makeUsername uname) password)


fakeRegister : String -> String -> Cmd msg
fakeRegister =
    fakeLogin

port module Api exposing
    ( AuthError(..)
    , AuthSuccess
    , Cred
    , Flags
    , account
    , application
    , authResponse
    , confirm
    , forgotPassword
    , get
    , login
    , logout
    , register
    , resetPassword
    , toUrl
    , updateEmail
    , updatePassword
    , userChanges
    , verifyEmail
    )

import Account exposing (Account)
import Browser
import Browser.Navigation as Nav
import Http exposing (Body)
import Json.Decode as Decode exposing (Decoder, Value, field, string)
import Json.Decode.Pipeline exposing (required)
import Url exposing (Url)
import Url.Builder exposing (QueryParameter)


type alias Flags =
    String



-- CRED


{-| Authentication credentials

We define Cred to limit the visibility of the token to this module. Username is
exposed and can be used in other modules.

-}
type Cred
    = Cred Account String


account : Cred -> Account
account (Cred acct _) =
    acct


credHeader : Cred -> Http.Header
credHeader (Cred _ str) =
    Http.header "authorization" str


credDecoder : Decoder Cred
credDecoder =
    Decode.succeed Cred
        |> required "account" Account.decoder
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
    Decode.decodeValue
        (storageDecoder userDecoder)
        val
        |> Result.toMaybe



-- AUTH


type CognitoResponse
    = CognitoSuccess
    | CognitoError String


type AuthSuccess
    = AuthSuccess


type AuthError
    = DecodeError Decode.Error
    | AuthError String


port cognitoRegister : Value -> Cmd msg


port cognitoConfirm : Value -> Cmd msg


port cognitoLogin : Value -> Cmd msg


port cognitoLogout : () -> Cmd msg


port cognitoUpdatePassword : Value -> Cmd msg


port cognitoUpdateEmail : Value -> Cmd msg


port cognitoVerifyEmail : Value -> Cmd msg


port cognitoForgotPassword : Value -> Cmd msg


port cognitoResetPassword : Value -> Cmd msg


port onCognitoResponse : (Value -> msg) -> Sub msg


register : Value -> Cmd msg
register registration =
    cognitoRegister registration


confirm : Value -> Cmd msg
confirm confirmationCode =
    cognitoConfirm confirmationCode


login : Value -> Cmd msg
login creds =
    cognitoLogin creds


logout : Cmd msg
logout =
    cognitoLogout ()


updatePassword : Value -> Cmd msg
updatePassword passwords =
    cognitoUpdatePassword passwords


updateEmail : Value -> Cmd msg
updateEmail email =
    cognitoUpdateEmail email


verifyEmail : Value -> Cmd msg
verifyEmail confirmationCode =
    cognitoVerifyEmail confirmationCode


forgotPassword : Value -> Cmd msg
forgotPassword username =
    cognitoForgotPassword username


resetPassword : Value -> Cmd msg
resetPassword resetInfo =
    cognitoResetPassword resetInfo


authResponse : (Result AuthError AuthSuccess -> msg) -> Sub msg
authResponse toMsg =
    onCognitoResponse (\value -> toMsg (toAuthResult (Decode.decodeValue decodeAuthResponse value)))


decodeAuthResponse : Decoder CognitoResponse
decodeAuthResponse =
    Decode.field "response" Decode.string
        |> Decode.andThen decodeAuthResult


decodeAuthResult : String -> Decoder CognitoResponse
decodeAuthResult result =
    case result of
        "success" ->
            Decode.succeed CognitoSuccess

        "error" ->
            Decode.field "message" Decode.string
                |> Decode.andThen (\message -> Decode.succeed (CognitoError message))

        _ ->
            Decode.fail <| "Something went wrong"


toAuthResult : Result Decode.Error CognitoResponse -> Result AuthError AuthSuccess
toAuthResult result =
    case result of
        Err error ->
            Err (DecodeError error)

        Ok value ->
            case value of
                CognitoSuccess ->
                    Ok AuthSuccess

                CognitoError err ->
                    Err (AuthError err)



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
                    Decode.decodeValue (storageDecoder userDecoder) flags
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



-- fakeLogin : String -> String -> Cmd msg
-- fakeLogin uname password =
--     storeCredWith (Cred (Username.makeUsername uname) password)
-- fakeRegister : String -> String -> Cmd msg
-- fakeRegister =
--     fakeLogin

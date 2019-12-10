module Page.Register exposing (Model, Msg(..), init, subscriptions, update, view)

{-| This module is adapted from the elm-spa-example: <https://github.com/rtfeldman/elm-spa-example/blob/master/src/Page/Register.elm>
-}

import Api
import Browser.Navigation as Nav exposing (pushUrl)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Http
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode
import Session exposing (Session)
import User exposing (User)


{-| We track session, problems, and form data in the model.

Problems can come from form validation or some error reported by the server. The
form requests email, username, password, and password confirmation from the
user.

-}
type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry String
    | ServerError String


type alias Form =
    { email : String
    , username : String
    , password : String
    , confirmPassword : String
    }


init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , problems = []
      , form =
            { email = ""
            , username = ""
            , password = ""
            , confirmPassword = ""
            }
      }
    , Cmd.none
    )



-- UPDATE


{-| Update handles form submission, changes to content in input boxes,
and server response to a new sign up request.

SubmittedForm sends the HTTP POST to sign in using register (defined at the end
of this file). Form validation should be added here and a way to display
validation errors should be added to view. Note the use of CompletedLogin here
as the message we expect when we hear back from the server.

Entered\* each update the corresponding field in the model when a user adds or
deletes a character from an input.

CompletedLogin handles Err and OK responses from the server. In the OK case,
the server has sent us a username and token which we cache in localStorage. The
Err case only logs server errors at this point, but we should add a way to
display errors to the user.

-}
type Msg
    = SubmittedForm
    | EnteredUsername String
    | EnteredEmail String
    | EnteredPassword String
    | EnteredPasswordConfirmation String
      -- | CompletedLogin (Result Decode.Error Api.AuthResult)
    | CompletedLogin (Result Api.AuthError Api.AuthSuccess)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            -- TODO: add form validation
            ( { model | problems = [] }
            , register model.form
            )

        EnteredUsername username ->
            updateForm (\form -> { form | username = username }) model

        EnteredEmail email ->
            updateForm (\form -> { form | email = email }) model

        EnteredPassword password ->
            updateForm (\form -> { form | password = password }) model

        EnteredPasswordConfirmation password ->
            updateForm (\form -> { form | confirmPassword = password }) model

        CompletedLogin (Err error) ->
            let
                debug =
                    Debug.log "Error: " error
            in
            case error of
                Api.AuthError err ->
                    ( model, Cmd.none )

                Api.DecodeError err ->
                    ( model, Cmd.none )

        CompletedLogin (Ok authResult) ->
            let
                debug =
                    Debug.log "Auth Register OK with: " authResult
            in
            ( model, Nav.pushUrl (Session.navKey model.session) "confirm" )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


{-| View displays the sign up form.

This form needs to be expanded to display problems to users. Beyond that, it
could use design improvements. The current version was borrowed from Login and
is probably to cramped for a sign up form.

-}
view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 150, Font.family Fonts.quattrocentoFont ]
        [ column [ centerX, width (px 375), spacing 25 ]
            [ row [ centerX ] [ el [ Font.family Fonts.cinzelFont, Font.size 27 ] <| text "Sign up for Lunar Rocks" ]
            , row
                [ centerX
                , paddingXY 0 25
                , width fill
                , Background.color (rgba 0.2 0.2 0.2 1)
                , Border.color (rgba 0.36 0.38 0.45 0.1)
                , Border.rounded 3
                , Border.width 1
                ]
                [ column [ centerX, width (px 300), spacing 20 ]
                    [ Input.username
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.username
                        , placeholder = Nothing
                        , onChange = \username -> EnteredUsername username
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username")
                        }
                    , Input.email
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.email
                        , placeholder = Nothing
                        , onChange = \email -> EnteredEmail email
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Email")
                        }
                    , Input.newPassword
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.password
                        , placeholder = Nothing
                        , onChange = \password -> EnteredPassword password
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Password")
                        , show = False
                        }
                    , Input.newPassword
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.confirmPassword
                        , placeholder = Nothing
                        , onChange = \password -> EnteredPasswordConfirmation password
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Confirm Password")
                        , show = False
                        }
                    , Input.button
                        [ Border.color (rgba 0.36 0.38 0.45 1)
                        , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
                        , paddingXY 32 16
                        , Border.rounded 3
                        , Border.width 2
                        , width fill
                        ]
                        { onPress = Just SubmittedForm
                        , label = el [ centerX ] <| text "Sign up"
                        }
                    ]
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Api.authResponse (\authResult -> CompletedLogin authResult)



-- AUTH


{-| register packages up the form data and calls the API to register a user
-}
register : Form -> Cmd msg
register form =
    let
        json =
            Encode.object
                [ ( "email", Encode.string form.email )
                , ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                ]
    in
    Api.register json

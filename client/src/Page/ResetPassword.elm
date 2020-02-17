module Page.ResetPassword exposing (Model, Msg(..), init, subscriptions, update, view)

import Account
import Api
import Browser.Navigation as Nav exposing (pushUrl)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Fonts
import FormHelpers exposing (onEnter)
import Infobar exposing (Infobar)
import Json.Encode as Encode
import Process
import Session exposing (Session(..))
import Task
import User


type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    , infobar : Maybe Infobar
    }


type Problem
    = InvalidEntry ValidatedField String


{-| The Cognito user pool will accept username or email, but we call it
username in Form to match the Amplify API
-}
type alias Form =
    { username : String
    , confirmationCode : String
    , password : String
    , confirmPassword : String
    }


{-| Initialize the page with username filled in for logged in users
-}
init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , problems = []
      , form =
            case Session.user session of
                Just user ->
                    { username = Account.email (User.account user)
                    , confirmationCode = ""
                    , password = ""
                    , confirmPassword = ""
                    }

                Nothing ->
                    { username = ""
                    , confirmationCode = ""
                    , password = ""
                    , confirmPassword = ""
                    }
      , infobar = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredUsername String
    | EnteredConfirmationCode String
    | EnteredPassword String
    | EnteredPasswordConfirmation String
    | CompletedReset (Result Api.AuthError Api.AuthSuccess)
    | ClearInfobar


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok (Trimmed form) ->
                    ( { model | problems = [] }
                    , resetPassword form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredUsername username ->
            updateForm (\form -> { form | username = username }) model

        EnteredConfirmationCode confirmationCode ->
            updateForm (\form -> { form | confirmationCode = confirmationCode }) model

        EnteredPassword password ->
            updateForm (\form -> { form | password = password }) model

        EnteredPasswordConfirmation password ->
            updateForm (\form -> { form | confirmPassword = password }) model

        CompletedReset (Err error) ->
            ( case error of
                Api.AuthError err ->
                    { model
                        | infobar = Just <| Infobar.error err
                    }

                Api.DecodeError _ ->
                    { model
                        | infobar = Just <| Infobar.error "An internal decoding error occured. Please contact the developers."
                    }
            , Task.perform (\_ -> ClearInfobar) <| Process.sleep 2500
            )

        CompletedReset (Ok _) ->
            case model.session of
                LoggedIn _ _ ->
                    ( { model
                        | form =
                            { username = ""
                            , confirmationCode = ""
                            , password = ""
                            , confirmPassword = ""
                            }
                        , infobar = Just <| Infobar.success "Password updated successfully"
                      }
                    , Task.perform (\_ -> ClearInfobar) <| Process.sleep 2500
                    )

                Anonymous _ ->
                    ( model, Nav.pushUrl (Session.navKey model.session) "login" )

        ClearInfobar ->
            ( { model | infobar = Nothing }, Cmd.none )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row
        [ centerX
        , height fill
        , width fill
        , paddingXY 0 150
        , Font.family Fonts.quattrocentoFont
        , inFront <|
            case model.infobar of
                Just infobar ->
                    row [ alignBottom, width fill, paddingXY 0 30 ]
                        [ Infobar.view infobar ClearInfobar ]

                Nothing ->
                    el [] none
        ]
        [ column [ centerX, alignTop, width (px 375), spacing 25 ]
            [ row [ centerX ] [ el [ Font.family Fonts.cinzelFont, Font.size 27 ] <| text "Reset Password" ]
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
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.username
                        , placeholder = Nothing
                        , onChange = \username -> EnteredUsername username
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username or Email")
                        }
                    , Input.text
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.confirmationCode
                        , placeholder = Nothing
                        , onChange = \email -> EnteredConfirmationCode email
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Confirmation Code")
                        }
                    , Input.newPassword
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.password
                        , placeholder = Nothing
                        , onChange = \password -> EnteredPassword password
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Password")
                        , show = False
                        }
                    , Input.newPassword
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
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
                        , Font.family Fonts.cinzelFont
                        ]
                        { onPress = Just SubmittedForm
                        , label = el [ centerX ] <| text "Submit"
                        }
                    ]
                ]
            , row [ centerX ]
                [ column [ spacing 10 ] (List.map viewProblem model.problems)
                ]
            ]
        ]


viewProblem : Problem -> Element msg
viewProblem (InvalidEntry _ error) =
    row
        [ centerX ]
        [ el [ Font.size 18 ] <|
            text error
        ]



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Api.authResponse (\authResult -> CompletedReset authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Username
    | ConfirmationCode
    | Password
    | ConfirmPassword


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
    , ConfirmationCode
    , Password
    , ConfirmPassword
    ]


{-| Trim the form and validate its fields. If there are problems, report them!
-}
validate : Form -> Result (List Problem) TrimmedForm
validate form =
    let
        trimmedForm =
            trimFields form
    in
    case List.concatMap (validateField trimmedForm) fieldsToValidate of
        [] ->
            Ok trimmedForm

        problems ->
            Err problems


validateField : TrimmedForm -> ValidatedField -> List Problem
validateField (Trimmed form) field =
    List.map (InvalidEntry field) <|
        case field of
            Username ->
                if String.isEmpty form.username then
                    [ "Username can't be blank." ]

                else
                    []

            ConfirmationCode ->
                if String.isEmpty form.confirmationCode then
                    [ "Confirmation code can't be blank." ]

                else
                    []

            Password ->
                if String.isEmpty form.password then
                    [ "Password can't be blank." ]

                else if String.length form.password < User.minPasswordChars then
                    [ "Password must be at least " ++ String.fromInt User.minPasswordChars ++ " characters long." ]

                else
                    []

            ConfirmPassword ->
                if String.isEmpty form.password then
                    [ "Cofirm password can't be blank." ]

                else if form.password /= form.confirmPassword then
                    [ "Password and Confirm Password must be the same." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { username = String.trim form.username
        , confirmationCode = String.trim form.confirmationCode
        , password = String.trim form.password
        , confirmPassword = String.trim form.confirmPassword
        }



-- AUTH


resetPassword : Form -> Cmd msg
resetPassword form =
    let
        json =
            Encode.object
                [ ( "username", Encode.string form.username )
                , ( "confirmationCode", Encode.string form.confirmationCode )
                , ( "newPassword", Encode.string form.password )
                ]
    in
    Api.resetPassword json

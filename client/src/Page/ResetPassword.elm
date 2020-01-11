module Page.ResetPassword exposing (Model, Msg(..), init, subscriptions, update, view)

import Account
import Api
import Browser.Navigation as Nav exposing (pushUrl)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Html.Events exposing (on)
import Json.Decode as Decode
import Json.Encode as Encode
import Session exposing (Session(..))
import User


type alias Model =
    { session : Session
    , message : String
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry ValidatedField String
    | AuthProblem String


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
      , message = ""
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
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError _ ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedReset (Ok _) ->
            case model.session of
                LoggedIn _ _ ->
                    ( { model | message = "Your password has been updated." }, Cmd.none )

                Anonymous _ ->
                    ( model, Nav.pushUrl (Session.navKey model.session) "login" )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 150, Font.family Fonts.quattrocentoFont ]
        [ column [ centerX, width (px 375), spacing 25 ]
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
                [ if List.isEmpty model.problems then
                    el [ Font.size 18 ] <|
                        text model.message

                  else
                    column [ spacing 10 ] <|
                        List.map viewProblem model.problems
                ]
            ]
        ]


viewProblem : Problem -> Element msg
viewProblem problem =
    let
        errorMessage =
            case problem of
                InvalidEntry _ error ->
                    error

                AuthProblem error ->
                    error
    in
    row [ centerX ] [ el [ Font.size 18 ] <| text errorMessage ]


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute <|
        Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )



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

module Page.Settings.Email exposing (Model, Msg, init, subscriptions, update, viewForm)

import Account exposing (Account)
import Api
import Element exposing (..)
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Html.Events exposing (on)
import Json.Decode as Decode exposing (field, string)
import Json.Encode as Encode



{- Email is a two-stage form:

   1. User submits a new email. A confirmation code is sent to the new email.
   2. User confirms the new email with the code

   EmailConfirmationStatus determines which stage is displayed. This starts off as EmailConfirmed
   because a user must have a confirmed email to login and access this form.
-}


type alias Model =
    { form : Form
    , message : String
    , problems : List Problem
    , confirmationStatus : EmailConfirmationStatus
    }


type alias Form =
    { email : String
    , confirmationCode : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | AuthProblem String


type EmailConfirmationStatus
    = EmailConfirmed
    | AwaitingConfirmation


init : Account -> ( Model, Cmd Msg )
init account =
    ( { form =
            { email = Account.email account
            , confirmationCode = ""
            }
      , message = "We will send you a confirmation code when you update your email."
      , problems = []
      , confirmationStatus = EmailConfirmed
      }
    , Cmd.none
    )


type Msg
    = SubmittedEmailForm
    | EnteredEmail String
    | CompletedEmailUpdate (Result Api.AuthError Api.AuthSuccess)
    | SubmittedConfirmationForm
    | EnteredConfirmationCode String
    | CompletedEmailConfirmation (Result Api.AuthError Api.AuthSuccess)


update : Account -> Msg -> Model -> ( Model, Cmd Msg )
update account msg model =
    case msg of
        SubmittedEmailForm ->
            case validate emailFields model.form of
                Ok (Trimmed form) ->
                    ( model
                    , updateEmail form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredEmail email ->
            updateForm (\form -> { form | email = email }) model

        CompletedEmailUpdate (Err error) ->
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError _ ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedEmailUpdate (Ok _) ->
            ( { model
                | message = "We sent a confirmation code to your new email."
                , problems = []
                , confirmationStatus = AwaitingConfirmation
              }
            , Cmd.none
            )

        SubmittedConfirmationForm ->
            case validate confirmationFields model.form of
                Ok (Trimmed form) ->
                    ( model
                    , verifyEmail form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredConfirmationCode confirmationCode ->
            updateForm (\form -> { form | confirmationCode = confirmationCode }) model

        CompletedEmailConfirmation (Err error) ->
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError _ ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedEmailConfirmation (Ok _) ->
            ( { model
                | form = (\form -> { form | email = Account.email account, confirmationCode = "" }) model.form
                , message = "Your email has been updated."
                , problems = []
                , confirmationStatus = EmailConfirmed
              }
            , Cmd.none
            )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


viewForm : Model -> Element Msg
viewForm model =
    column [ width fill, spacing 20, Font.family Fonts.quattrocentoFont ]
        [ row
            [ width fill
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Border.color (rgba 0.22 0.24 0.28 1)
            ]
            [ el [ paddingXY 0 10, Font.size 28, Font.family Fonts.cinzelFont ] (text "Email")
            ]
        , row [ width fill ]
            [ column [ width fill, spacing 20 ] <|
                case model.confirmationStatus of
                    EmailConfirmed ->
                        [ Input.text
                            [ onEnter SubmittedEmailForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                            { text = model.form.email
                            , placeholder = Nothing
                            , onChange = \email -> EnteredEmail email
                            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Email")
                            }
                        , row []
                            [ if List.isEmpty model.problems then
                                el [ Font.size 18 ] <|
                                    text model.message

                              else
                                column [ spacing 10 ] <|
                                    List.map viewProblem model.problems
                            ]
                        , Input.button
                            [ width (px 225)
                            , Border.color (rgba 0.36 0.38 0.45 1)
                            , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
                            , paddingXY 32 16
                            , Border.rounded 3
                            , Border.width 2
                            , Font.family Fonts.cinzelFont
                            ]
                            { onPress = Just SubmittedEmailForm
                            , label = el [ centerX ] <| text "Update Email"
                            }
                        ]

                    AwaitingConfirmation ->
                        [ Input.text
                            [ onEnter SubmittedConfirmationForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                            { text = model.form.confirmationCode
                            , placeholder = Nothing
                            , onChange = \confirmationCode -> EnteredConfirmationCode confirmationCode
                            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Confirmation Code")
                            }
                        , row []
                            [ if List.isEmpty model.problems then
                                el [ Font.size 18, paddingXY 0 5 ] <|
                                    text model.message

                              else
                                column [ spacing 10 ] <|
                                    List.map viewProblem model.problems
                            ]
                        , Input.button
                            [ width (px 225)
                            , Border.color (rgba 0.36 0.38 0.45 1)
                            , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
                            , paddingXY 32 16
                            , Border.rounded 3
                            , Border.width 2
                            , Font.family Fonts.cinzelFont
                            ]
                            { onPress = Just SubmittedConfirmationForm
                            , label = el [ centerX ] <| text "Confirm"
                            }
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
    row [ Font.family Fonts.quattrocentoFont ] [ el [ Font.size 18 ] <| text errorMessage ]


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


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.confirmationStatus of
        EmailConfirmed ->
            Api.authResponse (\authResult -> CompletedEmailUpdate authResult)

        AwaitingConfirmation ->
            Api.authResponse (\authResult -> CompletedEmailConfirmation authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Email
    | ConfirmationCode


emailFields : List ValidatedField
emailFields =
    [ Email ]


confirmationFields : List ValidatedField
confirmationFields =
    [ ConfirmationCode ]


{-| Trim the form and validate its fields. If there are problems, report them!
-}
validate : List ValidatedField -> Form -> Result (List Problem) TrimmedForm
validate fieldsToValidate form =
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
            Email ->
                if String.isEmpty form.email then
                    [ "Email can't be blank." ]

                else
                    []

            ConfirmationCode ->
                if String.isEmpty form.confirmationCode then
                    [ "Invalid verification code provided, please try again." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { email = String.trim form.email
        , confirmationCode = String.trim form.confirmationCode
        }



-- AUTH


updateEmail : Form -> Cmd msg
updateEmail form =
    let
        json =
            Encode.object
                [ ( "email", Encode.string form.email )
                ]
    in
    Api.updateEmail json


verifyEmail : Form -> Cmd msg
verifyEmail form =
    let
        code =
            Encode.string form.confirmationCode
    in
    Api.verifyEmail code

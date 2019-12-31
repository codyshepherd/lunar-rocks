module Page.Settings.Password exposing (Model, Msg, init, subscriptions, update, viewForm)

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
import User


type alias Model =
    { message : String
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry ValidatedField String
    | AuthProblem String


type alias Form =
    { oldPassword : String
    , newPassword : String
    , confirmNewPassword : String
    }


init : Account -> ( Model, Cmd Msg )
init account =
    ( { message =
            "Your new password must be at least "
                ++ String.fromInt User.minPasswordChars
                ++ " characters long."
      , problems = []
      , form =
            { oldPassword = ""
            , newPassword = ""
            , confirmNewPassword = ""
            }
      }
    , Cmd.none
    )


type Msg
    = SubmittedForm
    | EnteredOldPassword String
    | EnteredNewPassword String
    | EnteredConfirmNewPassword String
    | CompletedPasswordUpdate (Result Api.AuthError Api.AuthSuccess)


update : Account -> Msg -> Model -> ( Model, Cmd Msg )
update account msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok validForm ->
                    ( model
                    , updatePassword model.form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredOldPassword oldPassword ->
            updateForm (\form -> { form | oldPassword = oldPassword }) model

        EnteredNewPassword newPassword ->
            updateForm (\form -> { form | newPassword = newPassword }) model

        EnteredConfirmNewPassword newPassword ->
            updateForm (\form -> { form | confirmNewPassword = newPassword }) model

        CompletedPasswordUpdate (Err error) ->
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError err ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedPasswordUpdate (Ok authResult) ->
            ( { model
                | message = "Your password has been updated."
                , problems = []
                , form =
                    { oldPassword = ""
                    , newPassword = ""
                    , confirmNewPassword = ""
                    }
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
            [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "Password") ]
        , row [ width fill ]
            [ column [ width fill, spacing 20 ]
                [ Input.currentPassword
                    [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                    { text = model.form.oldPassword
                    , placeholder = Nothing
                    , onChange = \newPassword -> EnteredOldPassword newPassword
                    , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Old Password")
                    , show = False
                    }
                , Input.newPassword
                    [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                    { text = model.form.newPassword
                    , placeholder = Nothing
                    , onChange = \password -> EnteredNewPassword password
                    , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "New Password")
                    , show = False
                    }
                , Input.newPassword
                    [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                    { text = model.form.confirmNewPassword
                    , placeholder = Nothing
                    , onChange = \password -> EnteredConfirmNewPassword password
                    , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Confirm New Password")
                    , show = False
                    }
                , link
                    [ alignLeft
                    , Font.size 16
                    , Font.color (rgb 0.47 0.61 0.93)
                    , mouseOver [ Font.color (rgb 0.38 0.55 0.92) ]
                    ]
                    { url = "/forgot-password"
                    , label = text "Forgot Password?"
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
                    { onPress = Just SubmittedForm
                    , label = el [ centerX ] <| text "Update Password"
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


subscriptions : Sub Msg
subscriptions =
    Api.authResponse (\authResult -> CompletedPasswordUpdate authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = OldPassword
    | NewPassword
    | ConfirmNewPassword


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ OldPassword
    , NewPassword
    , ConfirmNewPassword
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
            OldPassword ->
                if String.isEmpty form.oldPassword then
                    [ "Old password can't be blank." ]

                else if String.length form.oldPassword < User.minPasswordChars then
                    [ "Old password must have been at least " ++ String.fromInt User.minPasswordChars ++ " characters long." ]

                else
                    []

            NewPassword ->
                if String.isEmpty form.newPassword then
                    [ "New Password can't be blank." ]

                else if String.length form.newPassword < User.minPasswordChars then
                    [ "New password must be at least " ++ String.fromInt User.minPasswordChars ++ " characters long." ]

                else
                    []

            ConfirmNewPassword ->
                if String.isEmpty form.confirmNewPassword then
                    [ "Confirm New Password can't be blank." ]

                else if form.newPassword /= form.confirmNewPassword then
                    [ "New Password and Confirm New Password must be the same." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { oldPassword = String.trim form.oldPassword
        , newPassword = String.trim form.newPassword
        , confirmNewPassword = String.trim form.confirmNewPassword
        }



-- AUTH


updatePassword : Form -> Cmd msg
updatePassword form =
    let
        json =
            Encode.object
                [ ( "oldPassword", Encode.string form.oldPassword )
                , ( "newPassword", Encode.string form.newPassword )
                ]
    in
    Api.updatePassword json

module Page.ForgotPassword exposing (Model, Msg(..), init, subscriptions, update, view)

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
import Session exposing (Session)
import User


type alias Model =
    { session : Session
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
                    }

                Nothing ->
                    { username = ""
                    }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredUsername String
    | CompletedResetRequest (Result Api.AuthError Api.AuthSuccess)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok (Trimmed form) ->
                    ( { model | problems = [] }
                    , forgotPassword form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredUsername newUsername ->
            updateForm (\form -> { form | username = newUsername }) model

        CompletedResetRequest (Err error) ->
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError _ ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedResetRequest (Ok _) ->
            ( model, Nav.pushUrl (Session.navKey model.session) "reset-password" )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 150, Font.family Fonts.quattrocentoFont ]
        [ column [ centerX, width (px 375), spacing 25 ]
            [ row [ centerX ] [ el [ Font.family Fonts.cinzelFont, Font.size 27 ] <| text "Request Password Reset" ]
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
                        , onChange = \newUsername -> EnteredUsername newUsername
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username or Email")
                        }
                    , row [ width (px 300) ]
                        [ if List.isEmpty model.problems then
                            el [ Font.size 18 ] <|
                                text "We will send a reset code to your email."

                          else
                            column [ spacing 10 ] <|
                                List.map viewProblem model.problems
                        ]
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
    Api.authResponse (\authResult -> CompletedResetRequest authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Username


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
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
                    [ "Please enter your username or email." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { username = String.trim form.username
        }



-- AUTH


forgotPassword : Form -> Cmd msg
forgotPassword form =
    let
        username =
            Encode.string form.username
    in
    Api.forgotPassword username

module Page.Login exposing (Model, Msg(..), init, subscriptions, update, view)

import Api
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
import Session exposing (Session)
import Task


type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    , infobar : Maybe Infobar
    }


type Problem
    = InvalidEntry ValidatedField String


type alias Form =
    { username : String
    , password : String
    }


init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , problems = []
      , form =
            { username = ""
            , password = ""
            }
      , infobar = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredUsername String
    | EnteredPassword String
    | CompletedLogin (Result Api.AuthError Api.AuthSuccess)
    | ClearInfobar


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok (Trimmed form) ->
                    ( { model | problems = [] }
                    , login form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredUsername newUsername ->
            updateForm (\form -> { form | username = newUsername }) model

        EnteredPassword newPassword ->
            updateForm (\form -> { form | password = newPassword }) model

        CompletedLogin (Err error) ->
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

        CompletedLogin (Ok _) ->
            -- navigation to Home page handled by Session
            ( model, Cmd.none )

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
        , width fill
        , height fill
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
            [ row [ centerX ] [ el [ Font.family Fonts.cinzelFont, Font.size 27 ] <| text "Sign in to Lunar Rocks" ]
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
                    , Input.currentPassword
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.password
                        , placeholder = Nothing
                        , onChange = \newPassword -> EnteredPassword newPassword
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Password")
                        , show = False
                        }
                    , link
                        [ alignLeft
                        , Font.size 16
                        , Font.color (rgb255 120 156 237)
                        , mouseOver [ Font.color (rgb255 84 129 232) ]
                        ]
                        { url = "/forgot-password"
                        , label = text "Forgot Password?"
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
                        , label = el [ centerX ] <| text "Sign in"
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
    Api.authResponse (\authResult -> CompletedLogin authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Username
    | Password


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
    , Password
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

            Password ->
                if String.isEmpty form.password then
                    [ "Password can't be blank." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { username = String.trim form.username
        , password = String.trim form.password
        }



-- AUTH


login : Form -> Cmd msg
login form =
    let
        json =
            Encode.object
                [ ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                ]
    in
    Api.login json

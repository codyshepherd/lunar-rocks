module Page.Register exposing (Model, Msg(..), init, subscriptions, update, view)

import Api
import Browser.Navigation as Nav exposing (pushUrl)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Fonts
import FormHelpers exposing (onEnter)
import Json.Encode as Encode
import Session exposing (Session)
import User


{-| We track session, problems, and form data in the model.

Problems can come from form validation or an error reported by the Cognito.

-}
type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry ValidatedField String


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
and Cognito responses to a new sign up request.

SubmittedForm sends a request to AWS Cognito (via Amplify in JavaScript) to register a user.
We use CompletedRegistration after a response from Cognito.

-}
type Msg
    = SubmittedForm
    | EnteredUsername String
    | EnteredEmail String
    | EnteredPassword String
    | EnteredPasswordConfirmation String
    | CompletedRegistration (Result Api.AuthError Api.AuthSuccess)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok (Trimmed form) ->
                    ( { model | problems = [] }
                    , register form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredUsername username ->
            updateForm (\form -> { form | username = username }) model

        EnteredEmail email ->
            updateForm (\form -> { form | email = email }) model

        EnteredPassword password ->
            updateForm (\form -> { form | password = password }) model

        EnteredPasswordConfirmation password ->
            updateForm (\form -> { form | confirmPassword = password }) model

        CompletedRegistration (Err _) ->
            ( model, Cmd.none )

        CompletedRegistration (Ok _) ->
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
    row
        [ centerX
        , width fill
        , height fill
        , paddingXY 0 150
        , Font.family Fonts.quattrocentoFont
        ]
        [ column [ centerX, alignTop, width (px 375), spacing 25 ]
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
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.username
                        , placeholder = Nothing
                        , onChange = \username -> EnteredUsername username
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username")
                        }
                    , Input.email
                        [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.email
                        , placeholder = Nothing
                        , onChange = \email -> EnteredEmail email
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Email")
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
                        ]
                        { onPress = Just SubmittedForm
                        , label = el [ centerX ] <| text "Sign up"
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
    Api.authResponse (\authResult -> CompletedRegistration authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Username
    | Email
    | Password
    | ConfirmPassword


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
    , Email
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

            Email ->
                if String.isEmpty form.email then
                    [ "Email can't be blank." ]

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
        { email = String.trim form.email
        , username = String.trim form.username
        , password = String.trim form.password
        , confirmPassword = String.trim form.confirmPassword
        }



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

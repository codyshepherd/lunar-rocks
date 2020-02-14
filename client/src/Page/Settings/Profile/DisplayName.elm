module Page.Settings.Profile.DisplayName exposing (Model, Msg(..), init, subscriptions, update, viewForm)

import Api
import Element exposing (..)
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import FormHelpers exposing (onEnter)
import Json.Encode as Encode
import Profile exposing (Profile)


type alias Model =
    { message : String
    , problems : List Problem
    , form : Form
    }


type alias Form =
    { displayName : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | AuthProblem String


init : Profile -> ( Model, Cmd msg )
init profile =
    ( { message =
            "We will use your display name in your profile and in sessions."
      , problems = []
      , form = { displayName = Profile.displayName profile }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredDisplayName String
    | CompletedDisplayNameUpdate (Result Api.AuthError Api.AuthSuccess)


update : Profile -> Msg -> Model -> ( Model, Cmd Msg )
update profile msg model =
    case msg of
        SubmittedForm ->
            case validate displayNameFields model.form of
                Ok (Trimmed form) ->
                    ( model
                    , updateDisplayName form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredDisplayName displayName ->
            updateForm (\form -> { form | displayName = displayName }) model

        CompletedDisplayNameUpdate (Err error) ->
            case error of
                Api.AuthError err ->
                    ( { model | problems = AuthProblem err :: model.problems }, Cmd.none )

                Api.DecodeError _ ->
                    ( { model
                        | problems = AuthProblem "An internal decoding error occured. Please contact the developers." :: model.problems
                      }
                    , Cmd.none
                    )

        CompletedDisplayNameUpdate (Ok _) ->
            ( { model
                | message = "Your display name has been updated."
                , problems = []
              }
            , Cmd.none
            )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


viewForm : Model -> Element Msg
viewForm model =
    column [ width fill, spacing 20 ]
        [ row
            [ width fill
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Border.color (rgba 0.22 0.24 0.28 1)
            ]
            [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "Display Name")
            ]
        , Input.text
            [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
            { text = model.form.displayName
            , placeholder = Nothing
            , onChange = \displayName -> EnteredDisplayName displayName
            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Display name")
            }
        , row []
            [ if List.isEmpty model.problems then
                paragraph [ Font.size 18 ]
                    [ text model.message ]

              else
                column [ spacing 10 ] <|
                    List.map viewProblem model.problems
            ]
        , Input.button
            [ width (px 250)
            , Border.color (rgba 0.36 0.38 0.45 1)
            , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
            , paddingXY 32 16
            , Border.rounded 3
            , Border.width 2
            , Font.family Fonts.cinzelFont
            ]
            { onPress = Just SubmittedForm
            , label = el [ centerX ] <| text "Update Display Name"
            }
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
    row [ centerX, paddingXY 0 5 ] [ el [ Font.size 18 ] <| text errorMessage ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Api.authResponse (\authResult -> CompletedDisplayNameUpdate authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = DisplayName


displayNameFields : List ValidatedField
displayNameFields =
    [ DisplayName
    ]


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
            DisplayName ->
                if String.length form.displayName > 16 then
                    [ "Display name must be less than 16 characters." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { displayName = String.trim form.displayName
        }


updateDisplayName : Form -> Cmd msg
updateDisplayName form =
    let
        json =
            Encode.object
                [ ( "nickname", Encode.string form.displayName )
                ]
    in
    Api.updateDisplayName json

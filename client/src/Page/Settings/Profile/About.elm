module Page.Settings.Profile.About exposing (Model, Msg(..), init, subscriptions, update, viewForm)

import Api
import Element exposing (..)
import Element.Border as Border
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
    { bio : String
    , location : String
    , website : String
    }


type Problem
    = InvalidEntry ValidatedField String


init : Profile -> ( Model, Cmd msg )
init profile =
    ( { message = "We will display this information along with your sessions in your public profile."
      , problems = []
      , form =
            { bio = Profile.bio profile
            , location = Profile.location profile
            , website = Profile.website profile
            }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredBio String
    | EnteredLocation String
    | EnteredWebsite String
    | CompletedAboutUpdate (Result Api.AuthError Api.AuthSuccess)


update : Profile -> Msg -> Model -> ( Model, Cmd Msg )
update profile msg model =
    case msg of
        SubmittedForm ->
            case validate aboutFields model.form of
                Ok (Trimmed form) ->
                    ( model
                    , updateAbout form
                    )

                Err problems ->
                    ( { model | problems = problems }
                    , Cmd.none
                    )

        EnteredBio bio ->
            updateForm (\form -> { form | bio = bio }) model

        EnteredLocation location ->
            updateForm (\form -> { form | location = location }) model

        EnteredWebsite website ->
            updateForm (\form -> { form | website = website }) model

        CompletedAboutUpdate (Err _) ->
            ( model, Cmd.none )

        CompletedAboutUpdate (Ok _) ->
            ( { model | problems = [] }
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
            [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "About You")
            ]
        , Input.multiline
            [ height (px 150), spacing 12, Font.color (rgba 0 0 0 1) ]
            { text = model.form.bio
            , placeholder = Nothing
            , onChange = \bio -> EnteredBio bio
            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Bio")
            , spellcheck = True
            }
        , Input.text
            [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
            { text = model.form.location
            , placeholder = Nothing
            , onChange = \location -> EnteredLocation location
            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Location")
            }
        , Input.text
            [ onEnter SubmittedForm, spacing 12, Font.color (rgba 0 0 0 1) ]
            { text = model.form.website
            , placeholder = Nothing
            , onChange = \website -> EnteredWebsite website
            , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Website")
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
            [ width (px 225)
            , Border.color (rgba 0.36 0.38 0.45 1)
            , mouseOver [ Border.color (rgba 0.42 0.44 0.51 1) ]
            , paddingXY 32 16
            , Border.rounded 3
            , Border.width 2
            , Font.family Fonts.cinzelFont
            ]
            { onPress = Just SubmittedForm
            , label = el [ centerX ] <| text "Update Profile"
            }
        ]


viewProblem : Problem -> Element msg
viewProblem (InvalidEntry _ error) =
    row
        [ centerX ]
        [ el [ Font.size 18 ] <|
            text error
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Api.authResponse (\authResult -> CompletedAboutUpdate authResult)



-- FORM


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Bio
    | Location
    | Website


aboutFields : List ValidatedField
aboutFields =
    [ Bio
    , Location
    , Website
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
            Bio ->
                if String.length form.bio > 2048 then
                    [ "Please write a shorter bio." ]

                else
                    []

            Location ->
                if String.length form.location > 64 then
                    [ "Location must be less than 64 characters." ]

                else
                    []

            Website ->
                -- 2000 is a somehwat arbitrary length,
                -- but such is life: https://stackoverflow.com/a/417184/6513123
                if String.length form.website > 2000 then
                    [ "Website URL must be less than 2000 characters." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { bio = String.trim form.bio
        , location = String.trim form.location
        , website = String.trim form.website
        }


updateAbout : Form -> Cmd msg
updateAbout form =
    let
        json =
            Encode.object
                [ ( "custom:bio", Encode.string form.bio )
                , ( "custom:location", Encode.string form.location )
                , ( "website", Encode.string form.website )
                ]
    in
    Api.updateAbout json

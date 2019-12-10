module Page.Login exposing (Model, Msg(..), init, subscriptions, update, view)

{-| This module is adapted from the elm-spa-example: <https://github.com/rtfeldman/elm-spa-example/blob/master/src/Page/Login.elm>
-}

import Api
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Http
import Json.Encode as Encode
import Session exposing (Session)
import User exposing (User)


type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry String
    | ServerError String


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
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredUsername String
    | EnteredPassword String
    | CompletedLogin (Result Api.AuthError Api.AuthSuccess)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            -- TODO: add form validation
            ( { model | problems = [] }
            , login model.form
            )

        EnteredUsername newUsername ->
            updateForm (\form -> { form | username = newUsername }) model

        EnteredPassword newPassword ->
            updateForm (\form -> { form | password = newPassword }) model

        CompletedLogin (Err error) ->
            let
                debug =
                    Debug.log "Decode error: " error
            in
            case error of
                Api.AuthError err ->
                    ( model, Cmd.none )

                Api.DecodeError err ->
                    ( model, Cmd.none )

        CompletedLogin (Ok authResult) ->
            let
                debug =
                    Debug.log "Auth Confirm OK with: " authResult
            in
            -- navigation to home page handled by Session
            ( model, Cmd.none )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 150, Font.family Fonts.quattrocentoFont ]
        [ column [ centerX, width (px 375), spacing 25 ]
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
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.username
                        , placeholder = Nothing
                        , onChange = \newUsername -> EnteredUsername newUsername
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Username")
                        }
                    , Input.currentPassword
                        [ spacing 12, Font.color (rgba 0 0 0 1) ]
                        { text = model.form.password
                        , placeholder = Nothing
                        , onChange = \newPassword -> EnteredPassword newPassword
                        , label = Input.labelAbove [ alignLeft, Font.size 18, Font.color (rgba 1 1 1 1) ] (text "Password")
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
                        , label = el [ centerX ] <| text "Sign in"
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

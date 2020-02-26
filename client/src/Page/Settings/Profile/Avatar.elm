module Page.Settings.Profile.Avatar exposing (Model, Msg(..), init, subscriptions, update, viewForm)

import Api
import Avatar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Profile exposing (Profile)
import User exposing (User)


type alias Model =
    { profile : Profile
    , avatarUrl : String
    }


init : Profile -> ( Model, Cmd msg )
init profile =
    ( { profile = profile
      , avatarUrl = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Nop


update : Profile -> Msg -> Model -> ( Model, Cmd Msg )
update profile msg model =
    case msg of
        Nop ->
            ( model, Cmd.none )



-- VIEW


viewForm : Model -> Element Msg
viewForm model =
    column [ alignTop, width (px 240), spacing 15 ]
        [ row
            [ width fill
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Border.color (rgba 0.22 0.24 0.28 1)
            ]
            [ el [ Font.size 28, paddingXY 0 10, Font.family Fonts.cinzelFont ] (text "Profile Picture")
            ]
        , row
            [ centerX
            , width (px 200)
            , height (px 200)
            , Border.widthEach { bottom = 1, left = 1, right = 1, top = 1 }
            , Border.color (rgb 0.22 0.24 0.28)
            ]
            [ el [] <|
                image [ height (px 200), clip ] <|
                    Avatar.imageMeta <|
                        Profile.avatar model.profile
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

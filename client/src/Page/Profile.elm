module Page.Profile exposing (Model, Msg(..), init, update, view)

import Api
import Element exposing (..)
import Element.Events exposing (..)
import Element.Font as Font
import Element.Input as Input
import Fonts
import Http
import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Decode.Pipeline exposing (required)
import Session exposing (Session)


type alias Model =
    { session : Session
    , profile : Maybe Profile
    }


type alias Profile =
    { email : String }


init : Session -> String -> ( Model, Cmd Msg )
init session username =
    let
        maybeCred =
            Session.cred session
    in
    ( { session = session
      , profile = Nothing
      }
    , fetchProfile session username
    )



-- UPDATE


type Msg
    = CompletedProfileLoad (Result Http.Error Profile)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CompletedProfileLoad (Err error) ->
            let
                debug =
                    Debug.log "Error requesting profile: " error
            in
            ( model, Cmd.none )

        CompletedProfileLoad (Ok profile) ->
            let
                debug =
                    Debug.log "Profile returned from server: " profile
            in
            ( { model | profile = Just profile }, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    row [ centerX, width fill, paddingXY 0 10 ]
        [ column [ centerX, spacing 10, Font.family Fonts.quattrocentoFont ] <|
            case model.profile of
                Just profile ->
                    [ row [ width fill ]
                        [ column [ centerX ]
                            [ el [ centerX ] <|
                                text "Your email:"
                            , el
                                [ centerX ]
                              <|
                                text profile.email
                            ]
                        ]
                    ]

                Nothing ->
                    []
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


fetchProfile : Session -> String -> Cmd Msg
fetchProfile session username =
    let
        maybeCred =
            Session.cred session
    in
    Api.get (Api.toUrl [ username ] []) maybeCred profileDecoder
        |> Http.send CompletedProfileLoad


profileDecoder : Decoder Profile
profileDecoder =
    Decode.succeed Profile
        |> required "email" Decode.string

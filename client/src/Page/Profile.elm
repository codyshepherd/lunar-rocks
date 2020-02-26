module Page.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Avatar
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Fonts
import Html
import Html.Attributes
import Profile exposing (Profile)
import User exposing (User)


type alias Model =
    { profile : Maybe Profile
    , username : String
    }


init : User -> String -> ( Model, Cmd Msg )
init user route =
    let
        account =
            User.account user
    in
    if account.username == route then
        ( { profile = Just (User.profile user)
          , username = route
          }
        , Cmd.none
        )

    else
        ( { profile = Nothing
          , username = ""
          }
          -- not our logged in user
          -- make an HTTP request to get the user profile
        , Cmd.none
        )



-- UPDATE


type Msg
    = Nop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nop ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Element Msg
view model =
    case model.profile of
        Just profile ->
            row
                [ centerX
                , width (px 1000)
                , height fill
                , paddingXY 0 40
                , spacing 40
                ]
                [ column [ width fill, alignTop, spacing 40 ]
                    [ row [ spacing 20 ]
                        [ column
                            [ width (px 200)
                            , height (px 200)
                            , Border.width 1
                            , Border.color (rgb 0.22 0.24 0.28)
                            ]
                            [ el [] <|
                                image [ height (px 200), clip ] <|
                                    Avatar.imageMeta <|
                                        Profile.avatar profile
                            ]
                        , column [ alignTop, width (px 800), height fill, spacing 5 ]
                            [ el
                                [ Font.size 50
                                , Font.family Fonts.cinzelFont
                                ]
                                (text profile.displayName)
                            , el
                                [ paddingXY 5 0
                                , Font.size 24
                                , Font.color (rgb255 150 150 150)
                                ]
                                (text model.username)
                            , paragraph
                                [ paddingXY 5 10
                                , Font.size 18
                                , Font.color (rgb255 200 200 200)
                                ]
                                [ el [] (text profile.bio)
                                ]
                            , row [ alignBottom, padding 5, Font.size 16 ]
                                [ if String.isEmpty profile.location then
                                    el [] none

                                  else
                                    row
                                        [ spacing 5
                                        , paddingEach
                                            { top = 0
                                            , right = 20
                                            , left = 0
                                            , bottom = 0
                                            }
                                        ]
                                        [ el
                                            [ Font.color (rgb255 200 200 200)
                                            ]
                                          <|
                                            html (Html.i [ Html.Attributes.class "fa fa-map-marker-alt" ] [])
                                        , el
                                            [ Font.color (rgb255 200 200 200) ]
                                            (text profile.location)
                                        ]
                                , if String.isEmpty profile.website then
                                    el [] none

                                  else
                                    row [ spacing 5 ]
                                        [ el
                                            [ Font.color (rgb255 200 200 200)
                                            ]
                                          <|
                                            html (Html.i [ Html.Attributes.class "fa fa-globe" ] [])
                                        , newTabLink
                                            [ Font.color (rgb255 200 200 200) ]
                                            { label = el [] (text <| removeProtocol profile.website)
                                            , url = profile.website
                                            }
                                        ]
                                ]
                            ]
                        ]
                    , row [ width fill ]
                        [ column [ width fill, spacing 20 ]
                            [ el
                                [ Font.size 36
                                , Font.family Fonts.cinzelFont
                                ]
                              <|
                                text "Sessions"
                            , row
                                [ width fill
                                , height (px 100)
                                , Border.width 2
                                , Border.color (rgb 0.22 0.24 0.28)
                                ]
                                []
                            , row
                                [ width fill
                                , height (px 100)
                                , Border.width 2
                                , Border.color (rgb 0.22 0.24 0.28)
                                ]
                                []
                            ]
                        ]
                    ]
                ]

        Nothing ->
            row
                [ centerX
                , width (px 1000)
                , paddingXY 0 40
                ]
                [ el
                    [ Font.size 36 ]
                    (text "User not found :'(")
                ]


removeProtocol : String -> String
removeProtocol url =
    case
        List.head <|
            List.drop 1 <|
                String.split "//" url
    of
        Just website ->
            website

        Nothing ->
            ""


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

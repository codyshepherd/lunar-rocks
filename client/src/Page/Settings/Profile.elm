module Page.Settings.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Account exposing (Account)
import Api
import Avatar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Fonts
import Infobar exposing (Infobar)
import Page.Settings.Profile.About as About
import Page.Settings.Profile.Avatar as Avatar
import Page.Settings.Profile.DisplayName as DisplayName
import Page.Settings.SettingsNav as SettingsNav
import Process
import Profile exposing (Profile)
import Task
import User exposing (User)


type alias Model =
    { account : Account
    , profile : Profile
    , aboutForm : About.Model
    , avatarForm : Avatar.Model
    , displayNameForm : DisplayName.Model
    , activeForm : ActiveForm
    , infobar : Maybe Infobar
    }


type ActiveForm
    = AboutForm
    | AvatarForm
    | DisplayNameForm


init : User -> ( Model, Cmd Msg )
init user =
    let
        profile =
            User.profile user

        ( aboutModel, _ ) =
            About.init profile

        ( avatarModel, _ ) =
            Avatar.init profile

        ( displayNameModel, _ ) =
            DisplayName.init profile
    in
    ( { account = User.account user
      , profile = User.profile user
      , aboutForm = aboutModel
      , avatarForm = avatarModel
      , displayNameForm = displayNameModel
      , activeForm = AvatarForm
      , infobar = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotAboutMsg About.Msg
    | GotAvatarMsg Avatar.Msg
    | GotDisplayNameMsg DisplayName.Msg
    | GotAuthInfo (Result Api.AuthError Api.AuthSuccess)
    | ClearInfobar


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAboutMsg subMsg ->
            let
                ( newAboutForm, subCmd ) =
                    About.update model.profile subMsg model.aboutForm
            in
            ( { model | aboutForm = newAboutForm, activeForm = AboutForm }
            , Cmd.map GotAboutMsg subCmd
            )

        GotAvatarMsg subMsg ->
            let
                ( newAvatarForm, subCmd ) =
                    Avatar.update model.profile subMsg model.avatarForm
            in
            ( { model | avatarForm = newAvatarForm, activeForm = AvatarForm }
            , Cmd.map GotAvatarMsg subCmd
            )

        GotDisplayNameMsg subMsg ->
            let
                ( newDisplayNameForm, subCmd ) =
                    DisplayName.update model.profile subMsg model.displayNameForm
            in
            ( { model | displayNameForm = newDisplayNameForm, activeForm = DisplayNameForm }
            , Cmd.map GotDisplayNameMsg subCmd
            )

        GotAuthInfo (Err error) ->
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

        GotAuthInfo (Ok (Api.AuthSuccess maybeInfo)) ->
            ( { model
                | infobar = Maybe.map Infobar.success maybeInfo
              }
            , Task.perform (\_ -> ClearInfobar) <| Process.sleep 2500
            )

        ClearInfobar ->
            ( { model | infobar = Nothing }, Cmd.none )


view : Model -> Element Msg
view model =
    row
        [ centerX
        , width (px 1000)
        , height fill
        , paddingXY 0 40
        , spacing 40
        , inFront <|
            case model.infobar of
                Just infobar ->
                    row [ alignBottom, width fill, paddingXY 0 30 ]
                        [ Infobar.view infobar ClearInfobar ]

                Nothing ->
                    el [] none
        ]
        [ SettingsNav.view SettingsNav.profile
        , column [ centerX, width (px 740), height fill, spacing 20 ] <|
            [ row [ width fill ]
                [ el [ Font.size 50, Font.family Fonts.cinzelFont ] <| text "Profile"
                , link
                    [ alignRight
                    , centerY
                    , Border.color (rgba 0.36 0.38 0.45 1)
                    , paddingXY 10 10
                    , Border.rounded 3
                    , Border.width 1
                    , Font.family Fonts.cinzelFont
                    , Font.size 18
                    , mouseOver
                        [ Background.color (rgb255 51 57 77)
                        ]
                    ]
                  <|
                    { url = "/" ++ Account.username model.account, label = text "View Public Profile" }
                ]
            , row [ width fill, spacing 20 ]
                [ column [ alignTop, width (px 500), spacing 30 ]
                    [ DisplayName.viewForm model.displayNameForm
                        |> Element.map GotDisplayNameMsg
                    ]
                , Avatar.viewForm model.avatarForm
                    |> Element.map GotAvatarMsg
                ]
            , row [ width fill ]
                [ About.viewForm model.aboutForm
                    |> Element.map GotAboutMsg
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Api.authResponse (\authResult -> GotAuthInfo authResult)
        , case model.activeForm of
            AboutForm ->
                Sub.map GotAboutMsg (About.subscriptions model.aboutForm)

            AvatarForm ->
                Sub.map GotAvatarMsg (Avatar.subscriptions model.avatarForm)

            DisplayNameForm ->
                Sub.map GotDisplayNameMsg (DisplayName.subscriptions model.displayNameForm)
        ]
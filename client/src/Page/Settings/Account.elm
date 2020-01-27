module Page.Settings.Account exposing (Model, Msg(..), init, subscriptions, update, view)

import Account exposing (Account)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Fonts
import Page.Settings.Account.Email as Email
import Page.Settings.Account.Password as Password
import User exposing (User)



{- Account displays username and wraps forms to update password and email.

   We map in Html and Cmds from the password and email modules to display and respond to each.
   Subscriptions are determined by ActiveForm to direct Api.authResponse messages to
   the form the user is interacting with.
-}


type alias Model =
    { account : Account
    , passwordForm : Password.Model
    , emailForm : Email.Model
    , activeForm : ActiveForm
    }


type ActiveForm
    = PasswordForm
    | EmailForm


init : User -> ( Model, Cmd Msg )
init user =
    let
        account =
            User.account user

        ( passwordModel, _ ) =
            Password.init account

        ( emailModel, _ ) =
            Email.init account
    in
    ( { account = account
      , passwordForm = passwordModel
      , emailForm = emailModel
      , activeForm = PasswordForm
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotPasswordMsg Password.Msg
    | GotEmailMsg Email.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPasswordMsg subMsg ->
            let
                ( newPasswordForm, subCmd ) =
                    Password.update model.account subMsg model.passwordForm
            in
            ( { model | passwordForm = newPasswordForm, activeForm = PasswordForm }
            , Cmd.map GotPasswordMsg subCmd
            )

        GotEmailMsg subMsg ->
            let
                ( newEmailForm, subCmd ) =
                    Email.update model.account subMsg model.emailForm
            in
            ( { model | emailForm = newEmailForm, activeForm = EmailForm }
            , Cmd.map GotEmailMsg subCmd
            )


view : Model -> Element Msg
view model =
    row
        [ centerX
        , width (px 1000)
        , paddingXY 0 40
        , spacing 40
        ]
        [ settingsNav Account
        , column [ centerX, width (px 740), spacing 30, Font.family Fonts.cinzelFont ] <|
            [ column [ width fill, spacing 15 ]
                [ row
                    [ width fill ]
                    [ el [ Font.size 50, Font.family Fonts.cinzelFont ] <| text "Account" ]
                , row
                    [ width fill
                    , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                    , Border.color (rgba 0.22 0.24 0.28 1)
                    ]
                    [ el [ Font.size 28, paddingXY 0 10 ] (text "Username")
                    ]
                , row []
                    [ el [ Font.family Fonts.quattrocentoFont ] <|
                        text <|
                            "Your username is "
                                ++ Account.username model.account
                                ++ "."
                    ]
                ]
            , Password.viewForm model.passwordForm
                |> Element.map GotPasswordMsg
            , Email.viewForm model.emailForm
                |> Element.map GotEmailMsg
            ]
        ]


settingsNav : SettingsPage -> Element Msg
settingsNav page =
    column
        [ width (px 210)
        , alignTop
        , Border.color (rgba 0.36 0.38 0.45 1)
        , Border.rounded 3
        , Border.width 2
        ]
        [ el
            [ paddingXY 16 16
            , width fill
            , Font.color (rgb255 200 200 200)
            , Border.color (rgba 0.36 0.38 0.45 1)
            , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
            , Background.color (rgb255 51 57 77)
            ]
            (text "Settings")
        , link
            [ width fill
            , paddingXY 16 16
            , Border.color (rgba 0.36 0.38 0.45 1)
            , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
            ]
            { url = "/settings/account", label = text "Account" }
        , link
            [ paddingXY 16 16
            , width fill
            ]
            { url = "/settings/profile", label = text "Profile" }

        -- el [ Font.size 20, paddingXY 0 10 ] (text "Username")
        ]


type SettingsPage
    = Account
    | Profile



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.activeForm of
        PasswordForm ->
            Sub.map GotPasswordMsg Password.subscriptions

        EmailForm ->
            Sub.map GotEmailMsg (Email.subscriptions model.emailForm)

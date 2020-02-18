module Page.Settings.Account exposing (Model, Msg(..), init, subscriptions, update, view)

import Account exposing (Account)
import Api
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Fonts
import Infobar exposing (Infobar)
import Page.Settings.Account.Email as Email
import Page.Settings.Account.Password as Password
import Page.Settings.SettingsNav as SettingsNav
import Process
import Task
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
    , infobar : Maybe Infobar
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
      , infobar = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotPasswordMsg Password.Msg
    | GotEmailMsg Email.Msg
    | GotAuthInfo (Result Api.AuthError Api.AuthSuccess)
    | ClearInfobar


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
        [ SettingsNav.view SettingsNav.account
        , column [ centerX, width (px 740), height fill, spacing 30, Font.family Fonts.cinzelFont ] <|
            [ column [ width fill, spacing 20 ]
                [ el [ Font.size 50, Font.family Fonts.cinzelFont ] <| text "Account"
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Api.authResponse (\authResult -> GotAuthInfo authResult)
        , case model.activeForm of
            PasswordForm ->
                Sub.map GotPasswordMsg Password.subscriptions

            EmailForm ->
                Sub.map GotEmailMsg (Email.subscriptions model.emailForm)
        ]

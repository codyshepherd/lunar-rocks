module Page.Settings exposing (Model, Msg(..), init, subscriptions, update, view)

import Account exposing (Account)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Fonts
import Page.Settings.Email as Email
import Page.Settings.Password as Password
import User exposing (User)



{- Settings displays username and wraps forms to update password and email.

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
    row [ centerX, width fill, paddingXY 0 40 ]
        [ column [ centerX, width (px 800), spacing 30, Font.family Fonts.cinzelFont ] <|
            [ column [ width fill, spacing 15 ]
                [ row
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
    case model.activeForm of
        PasswordForm ->
            Sub.map GotPasswordMsg Password.subscriptions

        EmailForm ->
            Sub.map GotEmailMsg (Email.subscriptions model.emailForm)

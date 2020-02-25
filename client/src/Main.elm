module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Api
import Avatar exposing (Avatar)
import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)
import Infobar exposing (Infobar)
import Json.Decode exposing (Value)
import Nav
import Page.Confirm as Confirm
import Page.ForgotPassword as ForgotPassword
import Page.Home as Home
import Page.Login as Login
import Page.MusicSession as MusicSession
import Page.Profile as Profile
import Page.Register as Register
import Page.ResetPassword as ResetPassword
import Page.Settings.Account as AccountSettings
import Page.Settings.Profile as ProfileSettings
import Process
import Profile
import Routes exposing (Route)
import Session exposing (Session(..))
import Task
import Url
import User exposing (User)



-- MAIN


{-| Our application is initialized in Api so that we can handle credentials there.
-}
main : Program Value Model Msg
main =
    Api.application User.decoder
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }



-- MODEL


type alias Model =
    { session : Session
    , route : Route
    , page : Page
    , infobar : Maybe Infobar
    }


type Page
    = NotFound
    | Home Home.Model
    | Login Login.Model
    | AccountSettings AccountSettings.Model
    | Profile Profile.Model
    | ProfileSettings ProfileSettings.Model
    | Register Register.Model
    | Confirm Confirm.Model
    | ForgotPassword ForgotPassword.Model
    | ResetPassword ResetPassword.Model
    | MusicSession MusicSession.Model


init : Maybe User -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init maybeUser url navKey =
    let
        session =
            Session.fromUser navKey maybeUser

        model =
            { session = session
            , route = Routes.Home

            -- , route = Route.fromUrl url
            , page = Home { session = session, counter = 0 }
            , infobar = Nothing
            }
    in
    ( model, Cmd.none )
        |> loadCurrentPage model.session


loadCurrentPage : Session -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage session ( model, cmd ) =
    let
        ( page, newCmd ) =
            case model.route of
                Routes.Home ->
                    let
                        ( pageModel, pageCmd ) =
                            Home.init session
                    in
                    ( Home pageModel, Cmd.map HomeMsg pageCmd )

                Routes.Login ->
                    let
                        ( pageModel, pageCmd ) =
                            Login.init session
                    in
                    ( Login pageModel, Cmd.map LoginMsg pageCmd )

                Routes.Logout ->
                    ( Home { session = session, counter = 0 }
                    , Cmd.batch
                        [ Nav.replaceUrl (Session.navKey model.session) "/"
                        , Api.logout
                        ]
                    )

                Routes.Profile username ->
                    case session of
                        LoggedIn _ user ->
                            let
                                ( pageModel, pageCmd ) =
                                    Profile.init user username
                            in
                            ( Profile pageModel, Cmd.map ProfileMsg pageCmd )

                        Anonymous _ ->
                            let
                                ( pageModel, pageCmd ) =
                                    Home.init session
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmd )

                Routes.ProfileSettings ->
                    case session of
                        LoggedIn _ user ->
                            let
                                ( pageModel, pageCmd ) =
                                    ProfileSettings.init user
                            in
                            ( ProfileSettings pageModel, Cmd.map ProfileSettingsMsg pageCmd )

                        Anonymous _ ->
                            let
                                ( pageModel, pageCmd ) =
                                    Home.init session
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmd )

                Routes.AccountSettings ->
                    case session of
                        LoggedIn _ user ->
                            let
                                ( pageModel, pageCmd ) =
                                    AccountSettings.init user
                            in
                            ( AccountSettings pageModel, Cmd.map AccountSettingsMsg pageCmd )

                        Anonymous _ ->
                            let
                                ( pageModel, pageCmd ) =
                                    Home.init session
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmd )

                Routes.Register ->
                    let
                        ( pageModel, pageCmd ) =
                            Register.init session
                    in
                    ( Register pageModel, Cmd.map RegisterMsg pageCmd )

                Routes.Confirm ->
                    let
                        ( pageModel, pageCmd ) =
                            Confirm.init session
                    in
                    ( Confirm pageModel, Cmd.map ConfirmMsg pageCmd )

                Routes.ForgotPassword ->
                    let
                        ( pageModel, pageCmd ) =
                            ForgotPassword.init session
                    in
                    ( ForgotPassword pageModel, Cmd.map ForgotPasswordMsg pageCmd )

                Routes.ResetPassword ->
                    let
                        ( pageModel, pageCmd ) =
                            ResetPassword.init session
                    in
                    ( ResetPassword pageModel, Cmd.map ResetPasswordMsg pageCmd )

                Routes.MusicSession username sessionName ->
                    let
                        ( pageModel, pageCmd ) =
                            MusicSession.init
                    in
                    ( MusicSession pageModel, Cmd.map MusicSessionMsg pageCmd )

                Routes.NotFound ->
                    ( NotFound, Cmd.none )
    in
    ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )



-- UPDATE


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | GotAvatar Avatar
    | GotSession Session
    | GotAuthInfo (Result Api.AuthError Api.AuthSuccess)
    | ShowSuccessInfobar Dom.Viewport (Maybe String)
    | ShowErrorInfobar Dom.Viewport String
    | ClearInfobar
    | HomeMsg Home.Msg
    | LoginMsg Login.Msg
    | ProfileMsg Profile.Msg
    | ProfileSettingsMsg ProfileSettings.Msg
    | AccountSettingsMsg AccountSettings.Msg
    | RegisterMsg Register.Msg
    | ConfirmMsg Confirm.Msg
    | ForgotPasswordMsg ForgotPassword.Msg
    | ResetPasswordMsg ResetPassword.Msg
    | MusicSessionMsg MusicSession.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( OnUrlRequest urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (Session.navKey model.session) (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( OnUrlChange url, _ ) ->
            ( { model | route = Routes.fromUrl url }
            , Cmd.none
            )
                |> loadCurrentPage model.session

        ( GotAvatar avatar, _ ) ->
            ( model, Cmd.none )

        ( GotSession session, Login _ ) ->
            ( { model | session = session }
            , Nav.replaceUrl (Session.navKey session) "/"
            )

        ( GotSession session, _ ) ->
            case session of
                LoggedIn _ _ ->
                    ( { model | session = session }
                    , Cmd.none
                    )

                -- |> loadCurrentPage session
                Anonymous _ ->
                    ( { model | session = session }
                    , Nav.replaceUrl (Session.navKey session) "/"
                    )

        ( GotAuthInfo (Err error), _ ) ->
            let
                err =
                    case error of
                        Api.AuthError authError ->
                            authError

                        Api.DecodeError _ ->
                            "An internal decoding error occured. Please contact the developers."
            in
            ( model
            , Task.perform (\viewport -> ShowErrorInfobar viewport err) Dom.getViewport
            )

        ( GotAuthInfo (Ok (Api.AuthSuccess maybeInfo)), _ ) ->
            ( model
            , Task.perform (\viewport -> ShowSuccessInfobar viewport maybeInfo) Dom.getViewport
            )

        ( ShowSuccessInfobar viewport maybeInfo, _ ) ->
            ( { model
                | infobar = Maybe.map (Infobar.success viewport model.route) maybeInfo
              }
            , Task.perform (\_ -> ClearInfobar) <| Process.sleep 2500
            )

        ( ShowErrorInfobar viewport info, _ ) ->
            ( { model
                | infobar = Just <| Infobar.error viewport model.route info
              }
            , Task.perform (\_ -> ClearInfobar) <| Process.sleep 2500
            )

        ( ClearInfobar, _ ) ->
            ( { model | infobar = Nothing }, Cmd.none )

        ( HomeMsg subMsg, Home pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Home.update subMsg pageModel
            in
            ( { model | page = Home newPageModel }
            , Cmd.map HomeMsg newCmd
            )

        ( LoginMsg subMsg, Login pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Login.update subMsg pageModel
            in
            ( { model | page = Login newPageModel }
            , Cmd.map LoginMsg newCmd
            )

        ( ProfileMsg subMsg, Profile pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Profile.update subMsg pageModel
            in
            ( { model | page = Profile newPageModel }
            , Cmd.map ProfileMsg newCmd
            )

        ( ProfileSettingsMsg subMsg, ProfileSettings pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    ProfileSettings.update subMsg pageModel
            in
            ( { model | page = ProfileSettings newPageModel }
            , Cmd.map ProfileSettingsMsg newCmd
            )

        ( AccountSettingsMsg subMsg, AccountSettings pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    AccountSettings.update subMsg pageModel
            in
            ( { model | page = AccountSettings newPageModel }
            , Cmd.map AccountSettingsMsg newCmd
            )

        ( RegisterMsg subMsg, Register pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Register.update subMsg pageModel
            in
            ( { model | page = Register newPageModel }
            , Cmd.map RegisterMsg newCmd
            )

        ( ConfirmMsg subMsg, Confirm pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Confirm.update subMsg pageModel
            in
            ( { model | page = Confirm newPageModel }
            , Cmd.map ConfirmMsg newCmd
            )

        ( ForgotPasswordMsg subMsg, ForgotPassword pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    ForgotPassword.update subMsg pageModel
            in
            ( { model | page = ForgotPassword newPageModel }
            , Cmd.map ForgotPasswordMsg newCmd
            )

        ( ResetPasswordMsg subMsg, ResetPassword pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    ResetPassword.update subMsg pageModel
            in
            ( { model | page = ResetPassword newPageModel }
            , Cmd.map ResetPasswordMsg newCmd
            )

        ( MusicSessionMsg subMsg, MusicSession pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    MusicSession.update subMsg pageModel
            in
            ( { model | page = MusicSession newPageModel }
            , Cmd.map MusicSessionMsg newCmd
            )

        ( _, _ ) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Session.changes GotSession (Session.navKey model.session)
        , Api.authResponse (\authResult -> GotAuthInfo authResult)
        , case model.page of
            Home pageModel ->
                Sub.map HomeMsg (Home.subscriptions pageModel)

            Login _ ->
                Sub.map LoginMsg Login.subscriptions

            Profile _ ->
                Sub.none

            ProfileSettings pageModel ->
                Sub.map ProfileSettingsMsg (ProfileSettings.subscriptions pageModel)

            AccountSettings pageModel ->
                Sub.map AccountSettingsMsg (AccountSettings.subscriptions pageModel)

            Register _ ->
                Sub.map RegisterMsg Register.subscriptions

            Confirm _ ->
                Sub.map ConfirmMsg Confirm.subscriptions

            ForgotPassword _ ->
                Sub.map ForgotPasswordMsg ForgotPassword.subscriptions

            ResetPassword _ ->
                Sub.map ResetPasswordMsg ResetPassword.subscriptions

            MusicSession pageModel ->
                Sub.map MusicSessionMsg (MusicSession.subscriptions pageModel)

            NotFound ->
                Sub.none
        ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        Home pageModel ->
            Element.map HomeMsg (Home.view pageModel)
                |> viewWith model.session model.infobar "Home"

        Login pageModel ->
            Element.map LoginMsg (Login.view pageModel)
                |> viewWith model.session model.infobar "Login"

        Profile pageModel ->
            Element.map ProfileMsg (Profile.view pageModel)
                |> viewWith model.session model.infobar "Profile"

        ProfileSettings pageModel ->
            Element.map ProfileSettingsMsg (ProfileSettings.view pageModel)
                |> viewWith model.session model.infobar "Profile Settings"

        AccountSettings pageModel ->
            Element.map AccountSettingsMsg (AccountSettings.view pageModel)
                |> viewWith model.session model.infobar "Account Settings"

        Register pageModel ->
            Element.map RegisterMsg (Register.view pageModel)
                |> viewWith model.session model.infobar "Register"

        Confirm pageModel ->
            Element.map ConfirmMsg (Confirm.view pageModel)
                |> viewWith model.session model.infobar "Confirm"

        ForgotPassword pageModel ->
            Element.map ForgotPasswordMsg (ForgotPassword.view pageModel)
                |> viewWith model.session model.infobar "Forgot Password"

        ResetPassword pageModel ->
            Element.map ResetPasswordMsg (ResetPassword.view pageModel)
                |> viewWith model.session model.infobar "Reset Password"

        MusicSession pageModel ->
            Element.map MusicSessionMsg (MusicSession.view pageModel)
                |> viewWith model.session model.infobar "Session"

        NotFound ->
            { title = "Not Found"
            , body =
                [ layout [] <|
                    column [ width fill ] [ Nav.view model.session ]
                ]
            }


viewWith : Session -> Maybe Infobar -> String -> Element Msg -> { title : String, body : List (Html Msg) }
viewWith session maybeInfobar title content =
    { title = title
    , body =
        [ layout
            [ Background.color (rgba 0.16 0.16 0.16 1)
            , Font.color (rgba 1 1 1 1)
            ]
          <|
            column
                [ width fill
                , height fill
                , centerX
                , inFront <|
                    case maybeInfobar of
                        Just infobar ->
                            Infobar.view infobar ClearInfobar

                        Nothing ->
                            el [] none
                ]
                [ Nav.view session
                , content
                ]
        ]
    }

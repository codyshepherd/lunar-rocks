module Main exposing (Model, Msg(..), init, main, subscriptions, update, view, viewLink)

import Account
import Api
import Avatar
import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Fonts
import Html exposing (Html)
import Json.Decode exposing (Value)
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
import Routes exposing (Route)
import Session exposing (Session(..))
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
init maybeUser _ navKey =
    let
        session =
            Session.fromUser navKey maybeUser

        model =
            { session = session
            , route = Routes.Home
            , page = Home { session = session, counter = 0 }
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

                Routes.Profile username ->
                    let
                        ( pageModel, pageCmd ) =
                            Profile.init session username
                    in
                    ( Profile pageModel, Cmd.map ProfileMsg pageCmd )

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
    | GotSession Session
    | HomeMsg Home.Msg
    | LoginMsg Login.Msg
    | Logout
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

        ( GotSession session, _ ) ->
            -- It may be better to return to the previous page if the user
            -- was viewing a session or a profile. Also, check if a user logs
            -- out the session will be anonymous we may want to make sure they
            -- must return to Home.
            ( { model | session = session }
            , Nav.replaceUrl (Session.navKey session) "/"
            )
                |> loadCurrentPage model.session

        ( Logout, _ ) ->
            ( model, Api.logout )

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
                |> viewWith model.session "Home"

        Login pageModel ->
            Element.map LoginMsg (Login.view pageModel)
                |> viewWith model.session "Login"

        Profile pageModel ->
            Element.map ProfileMsg (Profile.view pageModel)
                |> viewWith model.session "Profile"

        ProfileSettings pageModel ->
            Element.map ProfileSettingsMsg (ProfileSettings.view pageModel)
                |> viewWith model.session "Profile Settings"

        AccountSettings pageModel ->
            Element.map AccountSettingsMsg (AccountSettings.view pageModel)
                |> viewWith model.session "Account Settings"

        Register pageModel ->
            Element.map RegisterMsg (Register.view pageModel)
                |> viewWith model.session "Register"

        Confirm pageModel ->
            Element.map ConfirmMsg (Confirm.view pageModel)
                |> viewWith model.session "Confirm"

        ForgotPassword pageModel ->
            Element.map ForgotPasswordMsg (ForgotPassword.view pageModel)
                |> viewWith model.session "Forgot Password"

        ResetPassword pageModel ->
            Element.map ResetPasswordMsg (ResetPassword.view pageModel)
                |> viewWith model.session "Reset Password"

        MusicSession pageModel ->
            Element.map MusicSessionMsg (MusicSession.view pageModel)
                |> viewWith model.session "Session"

        NotFound ->
            { title = "Not Found"
            , body =
                [ layout [] <|
                    column [ width fill ] [ viewNav model.session ]
                ]
            }


viewWith : Session -> String -> Element Msg -> { title : String, body : List (Html Msg) }
viewWith session title content =
    { title = title
    , body =
        [ layout
            [ Background.color (rgba 0.16 0.16 0.16 1)
            , Font.color (rgba 1 1 1 1)
            ]
          <|
            column [ width fill, centerX ]
                [ viewNav session
                , content
                ]
        ]
    }


viewNav : Session -> Element Msg
viewNav session =
    row
        [ width fill
        , paddingXY 0 15
        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
        , Border.color (rgba 0.11 0.12 0.14 1)
        ]
        [ column [ centerX, width fill, paddingXY 30 0 ]
            [ row [ width fill ]
                [ column [ alignLeft, Font.family Fonts.cinzelFont, Font.size 36 ]
                    [ viewLink "/" <| text "Lunar Rocks"
                    ]
                , column [ alignRight ]
                    [ row [ spacing 15, Font.family Fonts.quattrocentoFont, Font.size 18 ] <|
                        case session of
                            Session.LoggedIn _ user ->
                                let
                                    username =
                                        Account.username (User.account user)
                                in
                                -- [ viewLink ("/" ++ username) "Profile"
                                [ viewLink "/settings/account" <|
                                    row [ spacing 7 ]
                                        [ el [] <| image [ height (px 30), Border.rounded 50, clip ] (Avatar.imageMeta Avatar.noAvatar)
                                        , el [] <| text username
                                        ]
                                , el [ Events.onClick Logout, pointer ] <| text "Sign Out"

                                -- , viewLink ("/" ++ Username.toString (User.username user) ++ "/dopestep") "Session Test"
                                ]

                            Session.Anonymous _ ->
                                [ viewLink "/login" <| text "Sign in"
                                , viewLink "/register" <| text "Sign up"

                                -- , viewLink "/notFound"
                                ]
                    ]
                ]
            ]
        ]


viewLink : String -> Element msg -> Element msg
viewLink path label =
    link []
        { url = path
        , label = label
        }

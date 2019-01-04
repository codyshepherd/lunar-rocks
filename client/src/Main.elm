module Main exposing (Model, Msg(..), init, main, subscriptions, update, view, viewLink)

{- This module is adapted from elm-tutorial-app: https://github.com/sporto/elm-tutorial-app/blob/master/src/Main.elm and
   elm-spa-example: https://github.com/rtfeldman/elm-spa-example/blob/master/src/Main.elm
-}

import Api
import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Fonts
import Html exposing (Html)
import Json.Decode as Decode exposing (Value)
import Page.Home as Home
import Page.Login as Login
import Page.MusicSession as MusicSession
import Page.Profile as Profile
import Page.Register as Register
import Routes exposing (Route)
import Session exposing (Session)
import Url
import User exposing (User)
import Username



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
    | Profile Profile.Model
    | Register Register.Model
    | MusicSession MusicSession.Model


init : Maybe User -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init maybeUser _ navKey =
    let
        dbg =
            Debug.log "maybeUser: " maybeUser

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
                            Profile.init
                    in
                    ( Profile pageModel, Cmd.map ProfileMsg pageCmd )

                Routes.Register ->
                    let
                        ( pageModel, pageCmd ) =
                            Register.init session
                    in
                    ( Register pageModel, Cmd.map RegisterMsg pageCmd )

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
    | RegisterMsg Register.Msg
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

        ( RegisterMsg subMsg, Register pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Register.update subMsg pageModel
            in
            ( { model | page = Register newPageModel }
            , Cmd.map RegisterMsg newCmd
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
                Sub.none

            Profile _ ->
                Sub.none

            Register _ ->
                Sub.none

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

        Register pageModel ->
            Element.map RegisterMsg (Register.view pageModel)
                |> viewWith model.session "Register"

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
        [ column [ centerX, width (px 800) ]
            [ row [ width fill ]
                [ column [ alignLeft, Font.family Fonts.cinzelFont, Font.size 36 ]
                    [ viewLink "/" "Lunar Rocks"
                    ]
                , column [ alignRight ]
                    [ row [ spacing 15, Font.family Fonts.quattrocentoFont, Font.size 18 ] <|
                        case session of
                            Session.LoggedIn _ user ->
                                let
                                    username =
                                        Username.toString (User.username user)
                                in
                                [ viewLink ("/" ++ username) "Profile"
                                , el [ Events.onClick Logout, pointer ] <| text "Sign Out"

                                -- , viewLink ("/" ++ Username.toString (User.username user) ++ "/dopestep") "Session Test"
                                ]

                            Session.Anonymous _ ->
                                [ viewLink "/login" "Sign in"
                                , viewLink "/register" "Sign up"

                                -- , viewLink "/notFound"
                                ]
                    ]
                ]
            ]
        ]


viewLink : String -> String -> Element msg
viewLink path label =
    link []
        { url = path
        , label = text label
        }

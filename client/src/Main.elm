module Main exposing (Model, Msg(..), init, main, subscriptions, update, view, viewLink)

-- import Html.Attributes exposing (..)

import Api exposing (Flags)
import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Fonts
import Html exposing (Html)
import Page.Home as Home
import Page.Login as Login
import Page.Profile as Profile
import Page.Register as Register
import Page.Session as Session
import Routes exposing (Route)
import Url



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }



-- MODEL


type alias Model =
    { flags : Flags
    , key : Nav.Key
    , route : Route
    , page : Page
    }


type Page
    = NotFound
    | Home Home.Model
    | Login Login.Model
    | Profile Profile.Model
    | Register Register.Model
    | Session Session.Model


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        model =
            { flags = "placeholder"
            , key = key
            , route = Routes.Home
            , page = Home 0
            }
    in
    ( model, Cmd.none )
        |> loadCurrentPage


loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage ( model, cmd ) =
    let
        ( page, newCmd ) =
            case model.route of
                Routes.Home ->
                    let
                        ( pageModel, pageCmd ) =
                            Home.init model.flags
                    in
                    ( Home pageModel, Cmd.map HomeMsg pageCmd )

                Routes.Login ->
                    let
                        ( pageModel, pageCmd ) =
                            Login.init
                    in
                    ( Login pageModel, Cmd.map LoginMsg pageCmd )

                Routes.Profile ->
                    let
                        ( pageModel, pageCmd ) =
                            Profile.init model.flags
                    in
                    ( Profile pageModel, Cmd.map ProfileMsg pageCmd )

                Routes.Register ->
                    let
                        ( pageModel, pageCmd ) =
                            Register.init
                    in
                    ( Register pageModel, Cmd.map RegisterMsg pageCmd )

                Routes.Session sessionId ->
                    let
                        ( pageModel, pageCmd ) =
                            Session.init model.flags
                    in
                    ( Session pageModel, Cmd.map SessionMsg pageCmd )

                Routes.NotFound ->
                    ( NotFound, Cmd.none )
    in
    ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )



-- UPDATE


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | HomeMsg Home.Msg
    | LoginMsg Login.Msg
    | ProfileMsg Profile.Msg
    | RegisterMsg Register.Msg
    | SessionMsg Session.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( OnUrlRequest urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( OnUrlChange url, _ ) ->
            ( { model | route = Routes.fromUrl url }
            , Cmd.none
            )
                |> loadCurrentPage

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

        ( SessionMsg subMsg, Session pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Session.update subMsg pageModel
            in
            ( { model | page = Session newPageModel }
            , Cmd.map SessionMsg newCmd
            )

        ( _, _ ) ->
            ( model, Cmd.none )



-- updateWith : Model -> Msg -> ( Model, Cmd msg ) -> Page -> ( Model, Cmd Msg )
-- updateWith model msg ( newPageModel, newCmd ) page =
--     ( { model | page = page newPageModel }
--     , Cmd.map msg newCmd
--     )
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Home pageModel ->
            Sub.map HomeMsg (Home.subscriptions pageModel)

        Login pageModel ->
            Sub.none

        Profile pageModel ->
            Sub.none

        Register pageModel ->
            Sub.none

        Session pageModel ->
            Sub.map SessionMsg (Session.subscriptions pageModel)

        NotFound ->
            Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        Home pageModel ->
            Element.map HomeMsg (Home.view pageModel)
                |> viewWith "Home"

        Login pageModel ->
            Element.map LoginMsg (Login.view pageModel)
                |> viewWith "Login"

        Profile pageModel ->
            Element.map ProfileMsg (Profile.view pageModel)
                |> viewWith "Profile"

        Register pageModel ->
            Element.map RegisterMsg (Register.view pageModel)
                |> viewWith "Register"

        Session pageModel ->
            Element.map SessionMsg (Session.view pageModel)
                |> viewWith "Session"

        NotFound ->
            { title = "Not Found"
            , body =
                [ layout [] <|
                    column [ width fill ] [ viewNav ]
                ]
            }


viewWith : String -> Element Msg -> { title : String, body : List (Html Msg) }
viewWith title content =
    { title = title
    , body =
        [ layout
            [ Background.color (rgba 0.16 0.16 0.16 1)
            , Font.color (rgba 1 1 1 1)
            ]
          <|
            column [ width fill, centerX ]
                [ viewNav
                , content
                ]
        ]
    }


viewNav : Element Msg
viewNav =
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
                    [ row [ spacing 15, Font.family Fonts.quattrocentoFont, Font.size 18 ]
                        [ viewLink "/login" "Sign in"
                        , viewLink "/register" "Sign up"

                        -- , viewLink "/profile" "Profile"
                        -- , viewLink "/session/1" "Session 1"
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

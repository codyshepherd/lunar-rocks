module Nav exposing (view)

import Account
import Avatar
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Fonts
import Profile
import Session exposing (Session(..))
import User


view : Session -> Element msg
view session =
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
                                    account =
                                        User.account user

                                    username =
                                        Account.username account

                                    avatar =
                                        Profile.avatar <|
                                            User.profile user
                                in
                                -- [ viewLink ("/" ++ username) "Profile"
                                [ viewLink "/settings/account" <|
                                    row [ spacing 7 ]
                                        [ el [] <| image [ height (px 30), Border.rounded 50, clip ] (Avatar.imageMeta avatar)
                                        , el [] <| text username
                                        ]
                                , viewLink "/logout" <| text "Sign out"

                                -- , el [ Events.onClick logoutMsg, pointer ] <| text "Sign Out"
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

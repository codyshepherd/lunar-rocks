module Views exposing (..)

import Html exposing (Html, div, text, input, a, button, h2, hr)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Models exposing (..)
import Msgs exposing (..)
import Routing exposing (sessionPath, sessionsPath)


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "MUSIC" ]
        , hr [] []
        , page model
        ]


page : Model -> Html Msg
page model =
    case model.route of
        Home ->
            div []
                [ div [ style [ ( "fontWeight", "bold" ), ( "paddingBottom", "10px" ) ] ] [ text "~HOME~" ]
                , div [] (List.map viewSessionEntry model.sessions)
                , div [ style [ ( "paddingTop", "10px" ) ] ]
                    [ button [ onClick (AddSession (newId model.sessions)) ] [ text "Add Session" ] ]
                ]

        SessionRoute id ->
            div []
                [ div [ style [ ( "fontWeight", "bold" ), ( "paddingBottom", "10px" ) ] ]
                    [ text ("~SESSION " ++ id ++ "~") ]
                , div []
                    (List.map viewMessage model.session.messages)
                , input [ onInput Input, onEnter Send, style [ ( "marginTop", "10px" ) ] ] []
                , div [ style [ ( "paddingTop", "10px" ) ] ]
                    [ a [ href sessionsPath ] [ text "<- HOME" ] ]
                ]

        NotFoundRoute ->
            notFoundView


viewSessionEntry : String -> Html msg
viewSessionEntry sessionId =
    div []
        [ a [ href (sessionPath sessionId) ] [ text ("Session " ++ sessionId) ] ]


viewMessage : String -> Html msg
viewMessage msg =
    div [] [ text msg ]


notFoundView : Html msg
notFoundView =
    div []
        [ text "Not found"
        ]


newId : List SessionId -> SessionId
newId sessions =
    case List.head (List.reverse sessions) of
        Just head ->
            toString (Result.withDefault -1 (String.toInt head) + 1)

        Nothing ->
            "1"


onEnter : Msg -> Html.Attribute Msg
onEnter msg =
    let
        isEnter keycode =
            if keycode == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)

module Styles exposing (..)

import Color
import Style exposing (..)
import Style.Border as Border
import Style.Color as Color
import Style.Font as Font
import Style.Transition as Transition


type Styles
    = ActiveButton
    | Button
    | ErrorMessage
    | GridBlock
    | InstrumentLabel
    | Logo
    | Main
    | MessageInput
    | Navigation
    | NavOption
    | None
    | PlayOrange
    | PlayPurple
    | Rest
    | RowLabel
    | SelectedSessionButton
    | SessionButton
    | SmallHeading
    | SubHeading
    | Text


serif =
    [ Font.importUrl
        { url = "https://fonts.googleapis.com/css?family=Cinzel"
        , name = "Cinzel"
        }
    , Font.font "times new roman"
    , Font.font "times"
    , Font.font "serif"
    ]


sansSerif =
    [ Font.importUrl
        { url = "https://fonts.googleapis.com/css?family=Quattrocento+Sans"
        , name = "Quattrocento Sans"
        }
    , Font.font "helvetica"
    , Font.font "arial"
    , Font.font "sans-serif"
    ]


stylesheet : StyleSheet Styles variation
stylesheet =
    Style.styleSheet
        [ style ActiveButton
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 192 78 17)
            , hover [ Color.border (Color.rgb 230 93 20) ]
            , Color.text Color.white
            , Transition.all
            ]
        , style Button
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 91 96 115)
            , hover [ Color.border (Color.rgb 112 118 143) ]
            , Color.text Color.white
            , Transition.all
            ]
        , style ErrorMessage
            [ Font.size 18
            , Color.text (Color.rgb 240 0 0)
            ]
        , style GridBlock
            [ Color.background (Color.rgb 120 120 120) ]
        , style InstrumentLabel [ Font.size 20 ]
        , style Logo
            [ Font.typeface serif
            , Font.size 36
            ]
        , style Main
            [ Color.background (Color.rgb 40 40 40)
            , Color.text Color.white
            , Font.typeface sansSerif
            ]
        , style MessageInput
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 75 79 94)
            , Color.text Color.white
            ]
        , style Navigation
            [ Border.bottom 1
            , Color.background (Color.rgb 39 39 39)
            , Color.border (Color.rgb 28 31 36)
            , Color.text Color.white
            ]
        , style NavOption
            [ Font.typeface sansSerif
            , Font.size 18
            , hover [ Color.text (Color.rgb 200 200 200) ]
            , Transition.all
            ]
        , style None []
        , style PlayOrange
            [ Color.background (Color.rgb 215 88 19)
            , Color.text Color.white
            ]
        , style PlayPurple
            [ Color.background (Color.rgb 91 96 115)
            , Color.text Color.white
            ]
        , style Rest
            [ Color.background (Color.rgb 150 150 150)
            , Color.text Color.white
            ]
        , style RowLabel
            [ Color.background (Color.rgb 40 40 40)
            , Color.text (Color.rgb 160 160 160)
            , Font.size 10
            ]
        , style SelectedSessionButton
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 192 78 17)
            , Color.border (Color.rgb 192 78 17)
            , Color.text Color.white
            , Transition.all
            ]
        , style SessionButton
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 66 69 82)
            , Color.border (Color.rgb 66 69 82)
            , Color.text Color.white
            , Transition.all
            ]
        , style SmallHeading
            [ Font.typeface serif
            , Font.size 18
            ]
        , style SubHeading
            [ Font.typeface serif
            , Font.size 24
            ]
        , style Text [ Font.size 18 ]
        ]



-- Color.rgb 28 31 36
-- Color.rgb 171 0 0

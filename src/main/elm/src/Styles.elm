module Styles exposing (..)

import Color
import Style exposing (..)
import Style.Border as Border
import Style.Color as Color
import Style.Font as Font


type Styles
    = None
    | Main
    | InstrumentLabel
    | Text
    | Navigation
    | Heading
    | SubHeading
    | GridBlock
    | PlayPurple
    | PlayOrange
    | Rest
    | MessageInput
    | Button
    | SessionButton
    | SelectedSessionButton


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
        [ style None []
        , style Main
            [ Color.background (Color.rgb 40 40 40)
            , Color.text Color.white
            , Font.typeface sansSerif
            ]
        , style InstrumentLabel [ Font.size 20 ]
        , style Text [ Font.size 18 ]
        , style Navigation
            [ Border.bottom 1
            , Color.background (Color.rgb 39 39 39)
            , Color.border (Color.rgb 28 31 36)
            , Color.text Color.white
            ]
        , style Heading
            [ Font.typeface serif
            , Font.size 48
            ]
        , style SubHeading
            [ Font.typeface serif
            , Font.size 24
            ]
        , style GridBlock
            [ Color.background (Color.rgb 120 120 120) ]
        , style PlayPurple
            [ Color.background (Color.rgb 91 96 115)
            , Color.text Color.white
            ]
        , style PlayOrange
            [ Color.background (Color.rgb 215 88 19)
            , Color.text Color.white
            ]
        , style Rest
            [ Color.background (Color.rgb 150 150 150)
            , Color.text Color.white
            ]
        , style MessageInput
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 75 79 94)
            , Color.text Color.white
            ]
        , style Button
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 40 40 40)
            , Color.border (Color.rgb 91 96 115)
            , Color.text Color.white
            ]
        , style SessionButton
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 66 69 82)
            , Color.border (Color.rgb 66 69 82)
            , Color.text Color.white
            ]
        , style SelectedSessionButton
            [ Border.all 2
            , Border.rounded 3
            , Color.background (Color.rgb 192 78 17)
            , Color.border (Color.rgb 192 78 17)
            , Color.text Color.white
            ]
        ]



-- Color.rgb 28 31 36
-- Color.rgb 171 0 0

module Fonts exposing (cinzelFont, quattrocentoFont)

import Element.Font as Font


cinzelFont =
    [ Font.external
        { url = "https://fonts.googleapis.com/css?family=Cinzel"
        , name = "Cinzel"
        }
    , Font.serif
    ]


quattrocentoFont =
    [ Font.external
        { url = "https://fonts.googleapis.com/css?family=Quattrocento+Sans"
        , name = "Quattrocento Sans"
        }
    , Font.sansSerif
    ]

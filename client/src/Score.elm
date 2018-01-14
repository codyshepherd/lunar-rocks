module Score exposing (readGrid)

import Models exposing (..)


readGrid : List (List Int) -> TrackId -> String -> Int -> List Note
readGrid grid trackId instrument tones =
    let
        rows =
            List.map (List.indexedMap (,)) grid

        tupleGrid =
            List.indexedMap (,) rows
    in
        List.concatMap (\row -> readRow row 1 trackId instrument tones) tupleGrid


readRow : ( Int, List ( Int, Int ) ) -> Int -> TrackId -> String -> Int -> List Note
readRow ( row, cols ) noteStart trackId instrument tones =
    case cols of
        c :: d :: cs ->
            case Tuple.second c of
                0 ->
                    readRow ( row, (d :: cs) ) (noteStart + 1) trackId instrument tones

                _ ->
                    if (Tuple.second d > Tuple.second c) then
                        readRow ( row, (d :: cs) ) noteStart trackId instrument tones
                    else
                        readCell ( row, c ) noteStart trackId instrument tones
                            :: readRow ( row, (d :: cs) ) (noteStart + Tuple.second c) trackId instrument tones

        c :: cs ->
            case Tuple.second c of
                0 ->
                    []

                _ ->
                    readCell ( row, c ) noteStart trackId instrument tones
                        :: readRow ( row, cs ) (noteStart + Tuple.second c) trackId instrument tones

        [] ->
            []


readCell : ( Int, ( Int, Int ) ) -> Int -> TrackId -> String -> Int -> Note
readCell ( row, ( col, action ) ) noteStart trackId instrument tones =
    Note trackId instrument noteStart action (tones - row)

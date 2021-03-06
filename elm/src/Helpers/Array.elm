module Helpers.Array exposing (..)

import Array exposing (..)
import List

delete : Int -> Array a -> Array a
-- TODO: A fast implementation is neccesary. Might pop up in Core.
delete i a =
    toIndexedList a |>
    List.filter (\(i_,x) -> i_ /= i)  |>
    List.map (\(i,x) -> x) |>
    fromList

modify : Int -> (a -> a) -> Array a -> Array a
modify i f arr =
    case get i arr of
        Nothing -> arr
        Just el -> set i (f el) arr


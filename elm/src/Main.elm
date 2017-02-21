module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)

import Material
import Material.Button as Button
import Material.Card as Card
import Material.Color as Color
import Material.Icon as Icon
import Material.Elevation as Elevation
import Material.Grid as Grid exposing (grid, cell, size, Device(..))
import Material.Layout as Layout
import Material.Options as Options
import Material.Table as Table
import Material.Textfield as Textfield

import Customer as C exposing (Customer)
import Booking  as B exposing (Booking)

import Date.Format as DateF

import Database as Db
import Http


main =
  Html.program
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions }

-- MODEL

type alias Mdl = Material.Model

type alias Model =
  { customerId : Maybe Int
  , customer : Customer
  , filter : String
  , focusedBooking : Maybe Booking
  , mdl : Mdl
  }

init : (Model, Cmd Msg)
init =
  ( Model
        Nothing
        (C.empty ())
        ""
        Nothing
        Material.model
  , Db.getLatestCustomer CustomerReceived "" )


-- UPDATE

type Msg
    = New
    | Previous
    | Next
    | Last
    | FilterChanged String
    | CustomerReceived (Result Http.Error Customer)
    | SelectBooking Booking
    | Ignore
    | Mdl (Material.Msg Msg)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    New ->
      let model_ =
        { model
        | customerId = Nothing
        , filter = ""
       }
      in
      ( model_ , Cmd.none )

    Previous ->
      case model.customerId of
        Just i ->
          ( model, Db.getPrevCustomerById CustomerReceived model.filter i)
        Nothing ->
          ( model, Db.getLatestCustomer CustomerReceived model.filter)

    Next ->
      case model.customerId of
        Just i ->
          ( model, Db.getNextCustomerById CustomerReceived model.filter i)
        Nothing ->
          ( model, Cmd.none )

    Last ->
      ( model, Db.getLatestCustomer CustomerReceived model.filter )

    FilterChanged str ->
      ( { model | filter = str }, Db.getLatestCustomer CustomerReceived str )

    CustomerReceived (Ok c) ->
      let model_ =
              { model
              | customer = c
              , customerId = c.customer_id
              , focusedBooking = List.head c.bookings
              }
      in
      ( model_ , Cmd.none )

    CustomerReceived (Err _) ->
      ( model , Cmd.none )

    SelectBooking booking ->
        ( { model | focusedBooking = Just booking } , Cmd.none )

    Ignore ->
        (model , Cmd.none)

    Mdl msg_ -> Material.update Mdl msg_ model


-- CARDS

defaultCardOptions : Options.Property c m
defaultCardOptions =
    Options.many
        [ Elevation.e2
        , Options.css "margin" "0.5em"
        , Options.css "width" "auto"
        ]

defaultActionsOptions : Options.Property () m
defaultActionsOptions =
    Options.many
        [ Options.center
        , Card.border
        ]

-- defaultActionsButton : String -> Html
defaultActionsButton mdl icon action =
    Button.render Mdl [0] mdl
        [ Button.colored
        , Button.minifab
        , Options.onClick action
        ]
        [ Icon.i icon ]


customerCard : Mdl -> Customer -> Html Msg
customerCard mdl c =
    let actions =
            [ defaultActionsButton mdl "mode_edit" Ignore
            ]
    in
    Card.view
        [ defaultCardOptions ]
        [ Card.title [] [ text c.keyword ]
        , Card.text [] [ C.view c ]
        , Card.actions [ defaultActionsOptions ] actions
        ]

bookingSelectionCard : Mdl -> (Booking -> Msg) -> List Booking
          -> Maybe Booking -> Html Msg
bookingSelectionCard mdl select bookings focused =
    let summaries = List.map B.summary bookings

        date d = Maybe.withDefault "" (Maybe.map (DateF.format "%d.%m.%y") d)
        range f t = text (date f ++ " bis " ++ date t)
        int  i = text (toString i)

        c = Options.css "text-align" "center"

        same a b = Maybe.withDefault False (Maybe.map ((==) b) a)

        row booking summary =
            Table.tr
                [ Options.onClick (select booking)
                , Table.selected
                    |> Options.when (same focused booking)
                ]
                [ Table.td [c] [range summary.from summary.to]
                , Table.td [c] [int summary.n_beds]
                , Table.td [c] [int summary.n_rooms]
                ]

        table =
            Table.table []
                [ Table.thead []
                    [ Table.tr []
                        [ Table.th [c] [Icon.i "date_range"]
                        , Table.th [c] [Icon.i "hotel"]
                        , Table.th [c] [Icon.i "vpn_key"]
                        ]
                    ]
                , Table.tbody [] (List.map2 row bookings summaries)
                ]

        actions =
            [ defaultActionsButton mdl "add" Ignore ]
    in
        Card.view
            [ defaultCardOptions ]
            [ Card.title [ Options.center ] [ table ]
            , Card.actions [ defaultActionsOptions ] actions
            ]

bookingCard : Booking -> Html Msg
bookingCard booking =
    Card.view
        [ defaultCardOptions ]
        [ Card.title [] [ text "Buchung" ]
        , Card.actions [] []
        ]

individualsCard: Mdl -> List B.BookedIndividual -> Html Msg
individualsCard mdl individuals =
    let birth i = text "n/a"
        given i = text i.given
        family i = text i.family

        left = Options.css "text-align" "left"
        right = Options.css "text-align" "right"

        row i =
            Table.tr []
                [ Table.td [left ] [given i]
                , Table.td [left ] [family i]
                , Table.td [right] [birth i]
                ]

        table =
            Table.table []
                [ Table.thead []
                    [ Table.tr []
                        [ Table.th [left ] [text "Vorname"]
                        , Table.th [left ] [text "Name"]
                        , Table.th [right] [text "Geburtsdatum"]
                        ]
                    ]
                , Table.tbody [] (List.map row individuals)
                ]

        actions =
            [ defaultActionsButton mdl "add" Ignore
            , defaultActionsButton mdl "mode_edit" Ignore
            ]
    in
        Card.view
            [ defaultCardOptions ]
            [ Card.title [ Options.center ] [ table ]
            , Card.actions [ defaultActionsOptions ] actions
            ]

roomCard : B.BookedRoom -> Html Msg
roomCard room =
    Card.view
        [ defaultCardOptions ]
        [ Card.title [] [ text "Zimmer" ]
        , Card.actions [] []
        ]

-- VIEW

view : Model -> Html Msg
view model =
    Layout.render Mdl model.mdl [ Layout.fixedHeader ]
        { header = [ controls model ]
        , drawer = []
        , tabs = ( [], [] )
        , main = [ viewBody model ]
        }

viewBody : Model -> Html Msg
viewBody model =
    let mdl = model.mdl

        customer = customerCard mdl model.customer

        selection = bookingSelectionCard mdl SelectBooking
            model.customer.bookings model.focusedBooking

        bookingCards b =  List.concat
            [ [ bookingCard b ]
            , [ individualsCard mdl b.individuals ]
            , List.map roomCard b.rooms
            ]
    in
        grid
            [ Grid.noSpacing
            ]
            [ cell [ size All 4 ] [ customer, selection ]
            , cell [ size All 4 ]
                ( Maybe.withDefault []
                    ( Maybe.map bookingCards model.focusedBooking )
                )
            ]

controls : Model -> Html Msg
controls model =
    let filter =
            -- Pure.textfield "Suche" FilterChanged model.filter
            Textfield.render Mdl [0] model.mdl
                [ Textfield.label "Suche"
                , Textfield.text_
                , Textfield.value model.filter
                , Options.onInput (FilterChanged)
                ] []

        filterIcon = Icon.view "search"
            [ Options.css "margin-right" "5px" ]

        btn action icon =
            Button.render Mdl [0] model.mdl
                [ Button.minifab
                , Button.colored
                , Options.onClick action
                ]
                [ Icon.i icon ]
    in
        Layout.row
            [ Color.background Color.accent
            , Color.text Color.primary
            ]
            [ filterIcon
            , filter
            , Layout.spacer
            , btn Previous "chevron_left"
            , btn Next "chevron_right"
            , btn Last "last_page"
            , Layout.spacer
            , btn New "library_add"
            ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



module Main exposing (..)

import Html exposing (Html, text, br, strong)
import Html.Attributes as Attributes

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
import Material.Typography as Typography

import Customer as C exposing (Customer)
import Booking  as B exposing (Booking)

import Defaults exposing (..)

import Cards.Note as NoteCard

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
  , customerNoteCard : NoteCard.Model
  , bookingNoteCard : NoteCard.Model
  , mdl : Mdl
  }

model : Model
model =
    { customerId = Nothing
    , customer = C.empty ()
    , filter = ""
    , customerNoteCard = NoteCard.show
    , bookingNoteCard = NoteCard.show
    , focusedBooking = Nothing
    , mdl = Material.model
    }

init : (Model, Cmd Msg)
init =
  ( model
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
    | DeleteCustomerNote
    | EditCustomerNote
    | EditCustomerNoteDone
    | DeleteBookingNote
    | EditBookingNote
    | EditBookingNoteDone
    | CustomerNoteCardMessage NoteCard.Msg
    | BookingNoteCardMessage NoteCard.Msg
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
              , customerNoteCard = NoteCard.show
              , bookingNoteCard = NoteCard.show
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

    DeleteCustomerNote ->
        let deleteNote c = { c | note = "" }
        in
            ( { model | customer = deleteNote model.customer }, Cmd.none )

    EditCustomerNote ->
        ( { model | customerNoteCard = NoteCard.edit model.customer.note }
        , Cmd.none )

    EditCustomerNoteDone ->
        let customer_ =
                NoteCard.extract model.customerNoteCard
                    |> Maybe.map (C.setNote model.customer)
                    |> Maybe.withDefault model.customer

            model_ =
                { model
                | customerNoteCard = NoteCard.show
                , customer = customer_
                }
        in
        ( model_ , Cmd.none )

    DeleteBookingNote ->
        let deleteNote c = { c | note = "" }
            model_ =
                { model
                -- TODO: Löschen wir hier nur in focusedBooking oder auch in
                -- bookings? Ersteres, da nach delete Markierung in Selection
                -- flöten geht. Focused und markiert sind nicht mehr gleich.
                -- FocusedBooking muss vermutlich umgebaut werden.
                -- Single Source of Truth violated !
                | focusedBooking = Maybe.map deleteNote model.focusedBooking
                }
        in
            (model_ , Cmd.none )

    EditBookingNote ->
        let noteCard_ =
                Maybe.map .note model.focusedBooking
                    |> Maybe.map NoteCard.edit
                    |> Maybe.withDefault NoteCard.show
        in
        ( { model | bookingNoteCard = noteCard_ }
        , Cmd.none )

    EditBookingNoteDone ->
        -- TODO : Compare EditCustomerNoteDone, but see note on
        -- DeleteBookingNote  first.
        ( { model | bookingNoteCard = NoteCard.show }
        , Cmd.none )

    CustomerNoteCardMessage msg_ ->
        let ( model_, cmd_) = NoteCard.update msg_ model.customerNoteCard
        in
            ( { model | customerNoteCard = model_ }
            , Cmd.map CustomerNoteCardMessage cmd_
            )

    BookingNoteCardMessage msg_ ->
        let ( model_, cmd_) = NoteCard.update msg_ model.bookingNoteCard
        in
            ( { model | bookingNoteCard = model_ }
            , Cmd.map BookingNoteCardMessage cmd_
            )

    Mdl msg_ -> Material.update Mdl msg_ model


-- CARDS

-- TODO: remove this hack as soon as all cards have their own module
defaultButton = Defaults.defaultButton Mdl

customerCard : Mdl -> Customer -> Html Msg
customerCard mdl c =
    let actions =
            [ defaultButton mdl "mode_edit" Ignore
            , defaultButton mdl "delete" Ignore
            ]

        -- TODO: export to Extra.List/String
        nonEmpty str =
            case String.trim str of
                "" -> Nothing
                str -> Just str

        joinNonEmpty sep lst =
            List.filterMap nonEmpty lst
                |> String.join sep

        append post pre =
            pre ++ post

        appendIfNotEmpty check post pre =
            case nonEmpty check of
                Nothing -> pre
                Just _  -> append post pre

        f str =
            appendIfNotEmpty str [ text str, br [] [] ]

        g = joinNonEmpty

        main_ = []
            |> f c.title
            |> f (g " " [c.given, c.second, c.family])
            |> f (g " " [c.street, c.street_number])
            |> f (g " " [g "-" [c.country_code, c.postal_code], c.city])
            |> f c.country

        main = Card.text [] main_

        company_ = []
            |> f c.company
            |> f c.company_address

        company =
            Card.text [] company_

        contact_fields = [c.phone, c.phone2, c.mobile, c.fax, c.fax2, c.mail
                            , c.mail2, c.web]

        contact_labels = ["Telefon", "Telefon", "Mobil", "Fax", "Fax", ""
                            , "", ""]

        h label value = case (label, value) of
            (l, "") -> []
            ("", v) -> [text v, br [] []]
            (l, v) -> List.map text [v, " (", l, ")"] ++ [br [] []]

        contact = Card.text []
            (List.concat (List.map2 h contact_labels contact_fields))

        contents =
            [ Card.title [ defaultCardTitle ] [ text c.keyword ]
            , main ]
            |> appendIfNotEmpty (c.company ++ c.company_address) [company]
            |> appendIfNotEmpty (String.join "" contact_fields)  [contact]
            |> append [ Card.actions [ defaultActions ] actions ]

    in
        Card.view [ defaultCard ] contents

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
            [ defaultButton mdl "add" Ignore ]
    in
        Card.view
            [ defaultCard ]
            [ Card.title [ defaultCardTitle ] [ text "Buchungen" ]
            , Card.title [ Options.center ] [ table ]
            , Card.actions [ defaultActions ] actions
            ]

bookingCard : Booking -> Html Msg
bookingCard booking =
    Card.view
        [ defaultCard ]
        [ Card.title [ defaultCardTitle] [ text "Buchung" ]
        , Card.actions [] []
        ]

individualsCard: Mdl -> List B.BookedIndividual -> Html Msg
individualsCard mdl individuals =
    let birth i = text
            ( Maybe.withDefault "n/a"
                ( Maybe.map (DateF.format "%d.%m.%Y") i.date_of_birth)
            )

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
            [ defaultButton mdl "add" Ignore
            , defaultButton mdl "mode_edit" Ignore
            ]
    in
        Card.view
            [ defaultCard ]
            [ Card.title [ defaultCardTitle ] [ text "Gäste" ]
            , Card.title [ Options.center ] [ table ]
            , Card.actions [ defaultActions ] actions
            ]

roomCard : B.BookedRoom -> Html Msg
roomCard room =
    Card.view
        [ defaultCard ]
        [ Card.title [ defaultCardTitle ] [ text "Zimmer" ]
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

        customerNoteConfig =
            { mdl        = model.mdl
            , mdlMessage = Mdl
            , msg        = CustomerNoteCardMessage
            , title      = "Kundennotiz"
            , delete     = DeleteCustomerNote
            , edit       = EditCustomerNote
            , done       = EditCustomerNoteDone
            }

        customerNote =
            NoteCard.view
                customerNoteConfig
                model.customerNoteCard
                model.customer.note

        selection = bookingSelectionCard mdl SelectBooking
            model.customer.bookings model.focusedBooking

        -- TODO: Helpers.Maybe
        maybeMapDefault default f x = Maybe.map f x |> Maybe.withDefault default

        bookingCards b =  List.concat
            [ [ bookingCard b ]
            , [ individualsCard mdl b.individuals ]
            , List.map roomCard b.rooms
            ]

        bookingNoteConfig =
            { customerNoteConfig
            | msg = BookingNoteCardMessage
            , title = "Buchungsnotiz"
            , delete = DeleteBookingNote
            , edit = EditBookingNote
            , done = EditBookingNoteDone
            }

        bookingNoteCard b =
            NoteCard.view
                bookingNoteConfig
                model.bookingNoteCard
                b.note

        bookingCards2 b = [ bookingNoteCard b ]
    in
        grid
            [ Grid.noSpacing
            ]
            [ cell [ size All 4 ] [ customer, customerNote, selection ]
            , cell [ size All 4 ]
                ( maybeMapDefault [] bookingCards model.focusedBooking )
            , cell [ size All 4 ]
                ( maybeMapDefault [] bookingCards2 model.focusedBooking )
            ]

controls : Model -> Html Msg
controls model =
    let filter =
            Textfield.render Mdl [0] model.mdl
                [ Textfield.label "Suche"
                , Textfield.text_
                , Textfield.value model.filter
                , Options.onInput (FilterChanged)
                ] []

        filterIcon = Icon.view "search"
            [ Options.css "margin-right" "5px" ]

        btn action icon = defaultButton model.mdl icon action
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



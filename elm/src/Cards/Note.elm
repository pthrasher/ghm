module Cards.Note exposing
    ( Model
    , Cfg
    , Msg
    , Callbacks
    , init
    , view
    , update
    )

import Material
import Material.Helpers exposing (pure, effect)
import Material.HelpersX exposing (callback, UpdateCallback)
import Material.Card as Card
import Material.Textfield as Textfield
import Material.Options as Options

import Defaults

import Markdown

import Html exposing (Html, text)
import Html.Attributes as Attributes

type alias Model =
    { editing : Bool
    , data    : String
    , buffer  : String
    }

type Msg msg
    = Change String
    | Edit
    | Done
    | Delete
    | Abort
    | Mdl (Material.Msg msg)

init : String -> Model
init str =
    { editing = False
    , buffer  = ""
    , data    = str
    }

edit : Model -> Model
edit model =
    { model
    | buffer  = model.data
    , editing = True
    }

type alias Callbacks msg =
    { mdl     : Material.Msg msg -> msg
    , updated : String           -> msg
    }

update : UpdateCallback m (Callbacks m) (Msg m) Model
update cb msg model =
    case msg of
        Change str ->
            pure { model | buffer = str }

        Abort ->
            pure { model | editing = False }

        Edit ->
            edit model |> pure

        Delete ->
            init "" |> callback (cb.updated "")

        Done ->
            String.trim model.buffer
            |> (\x -> init x |> callback (cb.updated x))

        Mdl msg ->
            callback (cb.mdl msg) model

-- View

type alias Cfg msg =
    { title : String
    , lift  : Msg  msg -> msg
    , index : List Int
    }

view : Cfg msg -> Material.Model -> Model -> Html msg
view cfg mdl model =
    Html.map cfg.lift <| case model.editing of
        True  -> viewEdit cfg mdl model
        False -> viewShow cfg mdl model


viewEdit : Cfg msg -> Material.Model -> Model -> Html (Msg msg)
viewEdit cfg mdl model =
    let i x = (x :: cfg.index)
        textfield =
            Textfield.render Mdl (i 1) mdl
                [ Textfield.value model.buffer
                , Textfield.textarea
                , Options.css "width" "100%"
                , Textfield.rows (model.buffer |> String.lines |> List.length)
                , Options.onInput Change
                ] ()

        defaultButton_ = Defaults.button Mdl mdl

        actions = [ defaultButton_ (i 2) "done"   Done
                  , defaultButton_ (i 3) "cancel" Abort
                  , defaultButton_ (i 4) "delete" Delete
                  ]

        cardContent =
            [ Card.title [ Defaults.cardTitle ] [ text cfg.title ]
            , Card.text [] [ textfield ]
            , Card.actions [ Defaults.actions ] actions
            ]

    in
        Card.view [ Defaults.card ] cardContent

viewShow : Cfg msg -> Material.Model -> Model -> Html (Msg msg)
viewShow cfg mdl model =
    let mdToHtml =
            Markdown.toHtmlWith Defaults.markdown
                [ Attributes.class "ghm_md_note" ]

        defaultButton_ = Defaults.button Mdl mdl

        i x = (x :: cfg.index)

        cardContent =
            case model.data of
                "" ->
                    [ Card.actions [ Options.center ]
                        [ defaultButton_ (i 5) "note_add" Edit ]
                    ]
                _  ->
                    [ Card.title [ Defaults.cardTitle ] [ text cfg.title ]
                    , Card.text [] [ mdToHtml model.data ]
                    , Card.actions [ Defaults.actions ]
                        [ defaultButton_ (i 6) "mode_edit" Edit
                        , defaultButton_ (i 7) "delete" Delete
                        ]
                    ]
    in
        Card.view [ Defaults.card ] cardContent


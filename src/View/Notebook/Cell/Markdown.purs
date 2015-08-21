module View.Notebook.Cell.Markdown (markdownOutput) where

import Prelude
import Data.Array (null)
import Data.Maybe (maybe)
import EffectTypes (NotebookAppEff())
import Input.Notebook (Input(..))
import Model.Notebook.Cell (Cell(), _cellId)
import Model.Notebook.Cell.Markdown (MarkdownRec(), _input, _state, _evaluated)
import Optic.Getter ((^.))
import Text.Markdown.SlamDown.Html (SlamDownEvent(), renderHalogen)
import View.Notebook.Common (HTML())
import View.Common (fadeWhen)
import View.Notebook.Common (HTML())

import qualified Halogen.HTML as H
import qualified Halogen.HTML.Attributes as A
import qualified Halogen.HTML.Events.Monad as E
import qualified View.Css as VC

type SlamDownHTML e = H.HTML (E.Event (NotebookAppEff e) SlamDownEvent)

markdownOutput :: forall e. MarkdownRec -> Cell -> Array (HTML e)
markdownOutput mr cell =
  maybe [] (optionalHTML <<< renderHalogen ("slamdata-frm-" ++ show (cell ^. _cellId)) (mr ^. _state)) (mr ^. _evaluated)
  where
  optionalHTML :: Array (SlamDownHTML e) -> Array (HTML e)
  optionalHTML md =
    if null md
    then [ ]
    else [ H.div [ A.classes ([ VC.markdownOutput ] <> (fadeWhen $ (mr ^. _input) == "")) ]
                 $ fromSlamDownEvents md
         ]

  fromSlamDownEvents :: Array (SlamDownHTML e) -> Array (HTML e)
  fromSlamDownEvents = map $ map $ map $ CellSlamDownEvent (cell ^. _cellId)

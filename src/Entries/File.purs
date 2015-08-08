module Entries.File where

import Prelude
import App.File (app)
import Control.Monad.Aff (launchAff)
import Control.Monad.Eff (Eff())
import Data.Tuple (Tuple(..))
import Driver.File (outside)
import Driver.ZClipboard (initZClipboard)
import EffectTypes (FileAppEff())
import Entries.Common (setSlamDataTitle)
import Halogen (runUIWith)
import Utils (onLoad, mountUI, setDocumentTitle)

main :: Eff (FileAppEff ()) Unit
main = onLoad $ void $ do
  launchAff setSlamDataTitle
  Tuple node driver <- runUIWith app postRender
  mountUI node
  outside driver
  where
  postRender _ node _ = initZClipboard node 

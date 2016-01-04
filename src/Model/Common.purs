{-
Copyright 2015 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module Model.Common
  ( browseURL
  , mkNotebookHash
  , mkNotebookURL
  ) where

import Prelude

import Control.UI.Browser as Browser

import Data.Foldable as F
import Data.Maybe as M
import Data.Path.Pathy ((</>))
import Data.Path.Pathy as P
import Data.StrMap as SM

import Model.Notebook.Action as Action
import Notebook.Cell.Port.VarMap as Port
import Model.Salt as Salt
import Model.Sort as Sort

import Utils.Path ((<./>))
import Utils.Path as UP

browseURL :: M.Maybe String -> Sort.Sort -> Salt.Salt -> UP.DirPath -> String
browseURL search sort salt path =
  Config.browserUrl
    <> "#?q=" <> q
    <> "&sort=" <> Sort.sort2string sort
    <> "&salt=" <> Salt.runSalt salt

  where
  search' =
    M.fromMaybe "" search # \s ->
      if s == "" then s else s <> " "

  q =
    Browser.encodeURIComponent $
      search'
        <> "path:\""
        <> P.printPath path
        <> "\""

mkNotebookHash :: String -> UP.DirPath -> Action.Action -> Port.VarMap -> String
mkNotebookHash name path action varMap =
  "#"
    <> UP.encodeURIPath (P.printPath $ path </> P.dir name <./> Config.notebookExtension)
    <> Action.printAction action
    <> renderVarMap varMap

  where
  renderVarMap varMap =
    if SM.isEmpty varMap
       then ""
       else "/?" <> F.intercalate "&" (varMapComponents varMap)

  varMapComponents =
    SM.foldMap $ \key val ->
      [ key
          <> "="
          <> Browser.encodeURIComponent (Port.renderVarMapValue val)
      ]

-- Currently the only place where modules from `Notebook.Model` are used
-- is `Controller.File`. I think that it would be better if url will be constructed
-- from things that are already in `FileSystem` (In fact that using of
-- `notebookURL` is redundant, because (state ^. _path) is `DirPath`
-- `theseRight $ That Config.newNotebookName` ≣ `Just Config.newNotebookName`
mkNotebookURL :: String -> UP.DirPath -> Action.Action -> String
mkNotebookURL name path action =
  Config.notebookUrl
    <> mkNotebookHash name path action SM.empty

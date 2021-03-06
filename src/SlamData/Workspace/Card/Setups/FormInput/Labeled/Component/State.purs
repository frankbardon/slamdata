{-
Copyright 2016 SlamData, Inc.

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

module SlamData.Workspace.Card.Setups.FormInput.Labeled.Component.State
  ( initialState
  , _value
  , _label
  , _name
  , _selected
  , State
  , module SlamData.Workspace.Card.Setups.DimensionPicker.CommonState
  ) where

import Data.Argonaut (JCursor)
import Data.Lens (Lens', lens)

import SlamData.Workspace.Card.Setups.FormInput.Labeled.Component.Query (Selection)
import SlamData.Workspace.Card.Setups.DimensionPicker.CommonState (showPicker)
import SlamData.Workspace.Card.Setups.DimensionPicker.CommonState as DS
import SlamData.Workspace.Card.Setups.FormInput.Labeled.Model as M

type State = M.ReducedState (DS.CommonState JCursor Selection ())

initialState ∷ State
initialState =
  { axes: M.initialState.axes
  , picker: DS.initial.picker
  , name: M.initialState.name
  , value: M.initialState.value
  , label: M.initialState.label
  , selected: M.initialState.selected
  }

_name ∷ ∀ r a. Lens' { name ∷ a | r} a
_name = lens _.name _ { name = _ }

_value ∷ ∀ r a. Lens' { value ∷ a | r } a
_value = lens _.value _ { value = _ }

_label ∷ ∀ r a. Lens' { label ∷ a | r } a
_label = lens _.label _ { label = _ }

_selected ∷ ∀ r a. Lens' { selected ∷ a | r } a
_selected = lens _.selected _ { selected = _ }

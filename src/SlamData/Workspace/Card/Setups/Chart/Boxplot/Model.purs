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

module SlamData.Workspace.Card.Setups.Chart.Boxplot.Model where

import SlamData.Prelude

import Data.Argonaut (JCursor, Json, decodeJson, (~>), (:=), isNull, jsonNull, (.?), jsonEmptyObject)
import Data.Lens ((^.))

import Test.StrongCheck.Arbitrary (arbitrary)
import Test.StrongCheck.Gen as Gen
import Test.StrongCheck.Data.Argonaut (runArbJCursor)

import SlamData.Workspace.Card.Setups.Behaviour as SB
import SlamData.Workspace.Card.Setups.Axis as Ax
import SlamData.Form.Select as S
import SlamData.Form.Select ((⊝))

type BoxplotR =
  { dimension ∷ JCursor
  , value ∷ JCursor
  , series ∷ Maybe JCursor
  , parallel ∷ Maybe JCursor
  }

type Model = Maybe BoxplotR

initialModel ∷ Model
initialModel = Nothing


eqBoxplotR ∷ BoxplotR → BoxplotR → Boolean
eqBoxplotR r1 r2 =
  r1.dimension ≡ r2.dimension
  ∧ r1.value ≡ r2.value
  ∧ r1.series ≡ r2.series
  ∧ r1.parallel ≡ r2.parallel

eqModel ∷ Model → Model → Boolean
eqModel Nothing Nothing = true
eqModel (Just r1) (Just r2) = eqBoxplotR r1 r2
eqModel _ _ = false

genModel ∷ Gen.Gen Model
genModel = do
  isNothing ← arbitrary
  if isNothing
    then pure Nothing
    else map Just do
    dimension ← map runArbJCursor arbitrary
    value ← map runArbJCursor arbitrary
    series ← map (map runArbJCursor) arbitrary
    parallel ← map (map runArbJCursor) arbitrary
    pure { dimension, value, series, parallel }

encode ∷ Model → Json
encode Nothing = jsonNull
encode (Just r) =
  "configType" := "boxplot"
  ~> "dimension" := r.dimension
  ~> "value" := r.value
  ~> "series" := r.series
  ~> "parallel" := r.parallel
  ~> jsonEmptyObject

decode ∷ Json → String ⊹ Model
decode js
  | isNull js = pure Nothing
  | otherwise = map Just do
    obj ← decodeJson js
    configType ← obj .? "configType"
    unless (configType ≡ "boxplot")
      $ throwError "THis is not boxplot"
    dimension ← obj .? "dimension"
    value ← obj .? "value"
    series ← obj .? "series"
    parallel ← obj .? "parallel"
    pure { dimension, value, series, parallel }

type ReducedState r =
  { axes ∷ Ax.Axes
  , dimension ∷ S.Select JCursor
  , value ∷ S.Select JCursor
  , series ∷ S.Select JCursor
  , parallel ∷ S.Select JCursor
  | r}

initialState ∷ ReducedState ()
initialState =
  { axes: Ax.initialAxes
  , dimension: S.emptySelect
  , value: S.emptySelect
  , series: S.emptySelect
  , parallel: S.emptySelect
  }


behaviour ∷ ∀ r. SB.Behaviour (ReducedState r) Model
behaviour =
  { synchronize
  , load
  , save
  }
  where
  synchronize st =
    let
      newDimension =
        S.setPreviousValueFrom (Just st.dimension)
          $ S.autoSelect
          $ S.newSelect
          $ st.axes.category
          ⊕ st.axes.time
          ⊕ st.axes.date
          ⊕ st.axes.datetime

      newValue =
        S.setPreviousValueFrom (Just st.value)
          $ S.autoSelect
          $ S.newSelect
          $ st.axes.value
          ⊝ newDimension

      newSeries =
        S.setPreviousValueFrom (Just st.series)
          $ S.newSelect
          $ S.ifSelected [newDimension]
          $ st.axes.category
          ⊕ st.axes.time
          ⊝ newDimension

      newParallel =
        S.setPreviousValueFrom (Just st.parallel)
          $ S.newSelect
          $ S.ifSelected [newDimension]
          $ st.axes.category
          ⊕ st.axes.time
          ⊝ newDimension
          ⊝ newSeries
    in
     st { value = newValue
        , dimension = newDimension
        , series = newSeries
        , parallel = newParallel
        }

  load Nothing st = st
  load (Just m) st =
    st { value = S.fromSelected $ Just m.value
       , dimension = S.fromSelected $ Just m.dimension
       , series = S.fromSelected m.series
       , parallel = S.fromSelected m.parallel
       }

  save st =
    { dimension: _
    , value: _
    , series: st.series ^. S._value
    , parallel: st.parallel ^. S._value
    }
    <$> (st.dimension ^. S._value)
    <*> (st.value ^. S._value)

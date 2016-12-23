module SlamData.Workspace.Card.FormInput.Component (formInputComponent) where

import SlamData.Prelude

import Halogen as H
import Halogen.HTML.Indexed as HH
import Halogen.HTML.Properties.Indexed as HP
import Halogen.Themes.Bootstrap3 as B

import SlamData.Monad (Slam)
--import SlamData.Render.CSS as RC
import SlamData.Workspace.Card.CardType as CT
--import SlamData.Workspace.Card.CardType.FormInputType (FormInputType)
import SlamData.Workspace.Card.CardType.FormInputType as FIT
import SlamData.Workspace.Card.Component as CC
import SlamData.Workspace.Card.FormInput.Component.ChildSlot as CS
--import SlamData.Workspace.Card.FormInput.Component.Query as Q
import SlamData.Workspace.Card.FormInput.Component.State as ST
import SlamData.Workspace.Card.FormInput.LabeledRenderer.Component as Labeled
import SlamData.Workspace.Card.FormInput.Model as M
import SlamData.Workspace.Card.FormInput.TextLikeRenderer.Component as TextLike
import SlamData.Workspace.Card.Model as Card
import SlamData.Workspace.Card.Port (Port(..))
import SlamData.Workspace.Card.Common.Render (renderLowLOD)
import SlamData.Workspace.LevelOfDetails (LevelOfDetails(..))

import Unsafe.Coerce (unsafeCoerce)

type HTML =
  H.ParentHTML CS.ChildState CC.CardEvalQuery CS.ChildQuery Slam CS.ChildSlot
type DSL =
  H.ParentDSL ST.State CS.ChildState CC.CardEvalQuery CS.ChildQuery Slam CS.ChildSlot

formInputComponent ∷ CC.CardOptions → H.Component CC.CardStateP CC.CardQueryP Slam
formInputComponent options = CC.makeCardComponent
  { options
  , cardType: CT.FormInput
  , component: H.parentComponent
      { render
      , eval
      , peek: Just (peek ∘ H.runChildF)
      }
  , initialState: H.parentState ST.initialState
  , _State: CC._FormInputState
  , _Query: CC.makeQueryPrism CC._FormInputQuery
  }

render ∷ ST.State → HTML
render state =
  HH.div_
    [ renderHighLOD state
    , renderLowLOD (CT.cardIconDarkImg CT.FormInput) id state.levelOfDetails
    ]

renderHighLOD ∷ ST.State → HTML
renderHighLOD state =
  HH.div
    [ HP.classes (guard (state.levelOfDetails ≠ High) $> B.hidden )]
    case state.formInputType of
      Just FIT.Text →
        textLike
      Just FIT.Numeric →
        textLike
      Just FIT.Date →
        textLike
      Just FIT.Time →
        textLike
      Just FIT.Datetime →
        textLike
      Just FIT.Dropdown →
        labeled
      Just FIT.Radio →
        labeled
      Just FIT.Checkbox →
        labeled
      _ → [ ]
  where
  textLike =
    [ HH.slot' CS.cpTextLike unit \_ →
       { component: TextLike.comp
       , initialState: TextLike.initialState
       }
    ]
  labeled =
    [ HH.slot' CS.cpLabeled unit \_ →
       { component: Labeled.comp
       , initialState: Labeled.initialState
       }
    ]

eval ∷ CC.CardEvalQuery ~> DSL
eval = case _ of
  CC.Activate next →
    pure next
  CC.Deactivate next →
    pure next
  CC.Save k →
    pure $ k $ unsafeCoerce unit
  CC.Load model next →
    case model of
      Card.FormInput (M.TextLike str) → do
        H.query' CS.cpTextLike unit $ H.action $ TextLike.ValueChanged str
        pure next
      Card.FormInput (M.Labeled set) → do
        H.query' CS.cpLabeled unit $ H.action $ Labeled.SetSelected set
        pure next
      _ →
        pure next
  CC.ReceiveInput input next →
    case input of
      SetupTextLikeFormInput p → do
        H.modify _{ formInputType = Just p.formInputType }
        H.query' CS.cpTextLike unit $ H.action $ TextLike.Setup p
        pure next
      SetupLabeledFormInput p → do
        H.modify _{ formInputType = Just p.formInputType }
        H.query' CS.cpLabeled unit $ H.action $ Labeled.Setup p
        pure next
      _ →
        pure next
  CC.ReceiveOutput _ next →
    pure next
  CC.ReceiveState _ next →
    pure next
  CC.ReceiveDimensions dims next → do
    H.modify _{levelOfDetails = if dims.width < 240.0 then Low else High}
    pure next
  CC.ModelUpdated _ next →
    pure next
  CC.ZoomIn next →
    pure next

peek ∷ ∀ a. CS.ChildQuery a → DSL Unit
peek _ = CC.raiseUpdatedP CC.EvalModelUpdate

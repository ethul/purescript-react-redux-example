module Example.App (main) where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, info)
import Control.Monad.Eff.Timer (TIMER, setTimeout)
import Control.Monad.Eff.Unsafe (unsafeCoerceEff)

import Data.Lens (Lens', Prism', lens, prism')
import Data.Maybe (Maybe(..), maybe)
import Data.Newtype (wrap)

import React as React
import React.DOM as DOM
import React.DOM.Props as Props

import React.Redux as Redux

type State = { counterA :: Int, counterB :: Int }

type StateA = { counterA :: Int }

type StateB = { counterB :: Int }

data Action = ActionA ActionA | ActionB ActionB

data ActionA = IncrementA | DelayedIncrementA Int

data ActionB = IncrementB

type Effect eff = (console :: CONSOLE, timer :: TIMER | eff)

store :: forall eff. Eff (Effect (Redux.ReduxEffect eff)) (Redux.Store Action State)
store = Redux.createStore reducer initialState (middlewareEnhancer <<< reduxDevtoolsExtensionEnhancer')
  where
  initialState :: State
  initialState = { counterA: 0, counterB: 0 }

  reduxDevtoolsExtensionEnhancer' :: Redux.Enhancer (Effect eff) Action State
  reduxDevtoolsExtensionEnhancer' = Redux.fromEnhancerForeign reduxDevtoolsExtensionEnhancer

  middlewareEnhancer :: Redux.Enhancer (Effect eff) Action State
  middlewareEnhancer = Redux.applyMiddleware [ loggerMiddleware, timeoutSchedulerMiddleware ]

  loggerMiddleware :: Redux.Middleware (Effect eff) Action State Unit
  loggerMiddleware { getState, dispatch } next action = do
    _ <- info showAction
    _ <- next action
    state <- getState
    logState state
    where
    logState :: State -> Eff (Effect (Redux.ReduxEffect eff)) Unit
    logState { counterA, counterB } = info ("state = { counterA: " <> show counterA <> ", " <> "counterB: " <> show counterB <> " }")

    showAction :: String
    showAction =
      case action of
           ActionA IncrementA -> "ActionA IncremementA"
           ActionA (DelayedIncrementA delay) -> "ActionA (DelayedIncrementA " <> show delay <> ")"
           ActionB IncrementB -> "ActionB IncremementB"

  timeoutSchedulerMiddleware :: Redux.Middleware (Effect eff) Action State Unit
  timeoutSchedulerMiddleware { getState, dispatch } next action =
    case action of
         ActionA (DelayedIncrementA delay) -> void (setTimeout delay (void (next action)))
         _ -> void (next action)

  reducer :: Redux.Reducer' Action State
  reducer =
    Redux.reducerOptic lensA prismA reducerA <<<
    Redux.reducerOptic lensB prismB reducerB
    where
    reducerA :: Redux.Reducer' ActionA StateA
    reducerA = wrap $ \action state ->
      case action of
           IncrementA -> state { counterA = state.counterA + 1 }
           DelayedIncrementA _ -> state { counterA = state.counterA + 1 }

    lensA :: Lens' State StateA
    lensA = lens (\s -> { counterA: s.counterA }) (\s b -> s { counterA = b.counterA })

    prismA :: Prism' Action ActionA
    prismA = prism' ActionA $
      case _ of
           ActionA a -> Just a
           _ -> Nothing

    reducerB :: Redux.Reducer' ActionB StateB
    reducerB = wrap $ \action state ->
      case action of
           IncrementB -> state { counterB = state.counterB + 1 }

    lensB :: Lens' State StateB
    lensB = lens (\s -> { counterB: s.counterB }) (\s b -> s { counterB = b.counterB })

    prismB :: Prism' Action ActionB
    prismB = prism' ActionB $
      case _ of
           ActionB a -> Just a
           _ -> Nothing

type IncrementAProps eff
  = { a :: Int
    , onIncrement :: Maybe Int -> Eff eff Unit
    }

incrementAClass :: forall eff. React.ReactClass (IncrementAProps eff)
incrementAClass = React.createClassStateless render
  where
  render :: IncrementAProps eff -> React.ReactElement
  render { a
         , onIncrement
         } =
    DOM.div []
            [ DOM.button [ Props.onClick (const $ unsafeCoerceEff (onIncrement Nothing)) ]
                         [ DOM.text ("Increment A: " <> show a) ]
            , DOM.button [ Props.onClick (const $ unsafeCoerceEff (onIncrement (Just 2000))) ]
                         [ DOM.text ("Increment A (delayed by 2s): " <> show a) ]
            ]

type IncrementBProps eff
  = { b :: Int
    , onIncrement :: Eff eff Unit
    }

incrementBClass :: forall eff. React.ReactClass (IncrementBProps eff)
incrementBClass = React.createClassStateless render
  where
  render :: IncrementBProps eff -> React.ReactElement
  render { b
         , onIncrement
         } =
    DOM.div []
            [ DOM.button [ Props.onClick (const $ unsafeCoerceEff onIncrement) ]
                         [ DOM.text ("Increment B: " <> show b) ]
            ]

incrementAComponent :: forall eff. Redux.ConnectClass' State (IncrementAProps eff)
incrementAComponent = Redux.connect stateToProps dispatchToProps incrementAClass
  where
  stateToProps :: State -> { } -> { a :: Int }
  stateToProps { counterA } ownProps = { a: counterA }

  dispatchToProps :: Redux.Dispatch' eff Action -> { } -> { onIncrement :: Maybe Int -> Eff eff Unit }
  dispatchToProps dispatch ownProps = { onIncrement: void <<< unsafeCoerceEff <<< dispatch <<< ActionA <<< maybe IncrementA DelayedIncrementA }

incrementBComponent :: forall eff. Redux.ConnectClass' State (IncrementBProps eff)
incrementBComponent = Redux.connect stateToProps dispatchToProps incrementBClass
  where
  stateToProps :: State -> { } -> { b :: Int }
  stateToProps { counterB } _ = { b: counterB }

  dispatchToProps :: Redux.Dispatch' eff Action -> { } -> { onIncrement :: Eff eff Unit }
  dispatchToProps dispatch _ = { onIncrement: void (unsafeCoerceEff (dispatch (ActionB IncrementB))) }

type AppProps = Unit

appClass :: React.ReactClass AppProps
appClass = React.createClass (React.spec unit render)
  where
  render :: forall eff. React.Render AppProps Unit eff
  render this = render' <$> React.getProps this
    where
    render' :: AppProps -> React.ReactElement
    render' _ =
      DOM.div []
              [ Redux.createElement_ incrementAComponent []
              , Redux.createElement_ incrementBComponent []
              ]

main :: forall eff. Eff (Effect (Redux.ReduxEffect eff)) React.ReactElement
main = do
  store' <- store

  let element = Redux.createProviderElement store' [ React.createElement appClass unit [] ]

  pure element

foreign import reduxDevtoolsExtensionEnhancer :: forall action state. Redux.EnhancerForeign action state

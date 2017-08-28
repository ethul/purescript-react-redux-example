module Example.App (main) where

import Prelude (Unit, (<$>), (+), (<>), (<<<), bind, id, pure, show, void)

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, info)
import Control.Monad.Eff.Timer (TIMER, setTimeout)
import Control.Monad.Eff.Unsafe (unsafeCoerceEff)

import Data.Lens (Lens', Prism', lens, prism')
import Data.Maybe (Maybe(..))

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

  reducer :: Redux.Reducer Action State
  reducer action =
    (Redux.reducerOptic lensA prismA reducerA) action <<<
    (Redux.reducerOptic lensB prismB reducerB) action
    where
    reducerA :: Redux.Reducer ActionA StateA
    reducerA action' state' =
      case action' of
           IncrementA -> state' { counterA = state'.counterA + 1 }
           DelayedIncrementA _ -> state' { counterA = state'.counterA + 1 }

    lensA :: Lens' State StateA
    lensA = lens (\s -> { counterA: s.counterA }) (\s b -> s { counterA = b.counterA })

    prismA :: Prism' Action ActionA
    prismA = prism' ActionA (\a -> case a of
                                        ActionA a' -> Just a'
                                        _ -> Nothing)

    reducerB :: Redux.Reducer ActionB StateB
    reducerB action' state' =
      case action' of
           IncrementB -> state' { counterB = state'.counterB + 1 }

    lensB :: Lens' State StateB
    lensB = lens (\s -> { counterB: s.counterB }) (\s b -> s { counterB = b.counterB })

    prismB :: Prism' Action ActionB
    prismB = prism' ActionB (\a -> case a of
                                        ActionB a' -> Just a'
                                        _ -> Nothing)

appClass :: Redux.ReduxReactClass' State State
appClass = Redux.createClass' id (Redux.spec' render)
  where
  render :: forall eff. Redux.Render State Unit eff (Eff (Redux.ReduxEffect eff)) Action
  render dispatch this = render' <$> React.getProps this
    where
    render' :: State -> React.ReactElement
    render' props =
      DOM.div []
              [ DOM.button [ Props.onClick (onClick (ActionA IncrementA)) ]
                           [ DOM.text ("Increment A: " <> show props.counterA) ]
              , DOM.button [ Props.onClick (onClick (ActionA (DelayedIncrementA 2000))) ]
                           [ DOM.text ("Increment A (delayed by 2s): " <> show props.counterA) ]
              , DOM.button [ Props.onClick (onClick (ActionB IncrementB)) ]
                           [ DOM.text ("Increment B: " <> show props.counterB) ]
              ]
      where
      onClick :: Action -> React.Event -> React.EventHandlerContext eff Unit Unit Unit
      onClick action event = void (unsafeCoerceEff (dispatch (pure action)))

main :: forall eff. Eff (Effect (Redux.ReduxEffect eff)) React.ReactElement
main = do
  store' <- store
  let element = Redux.createProviderElement store' appClass
  pure element

foreign import reduxDevtoolsExtensionEnhancer :: forall action state. Redux.EnhancerForeign action state

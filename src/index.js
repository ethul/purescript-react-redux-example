'use strict';

const ReactDOM = require('react-dom');

const App = require('./Example/App.purs');

// ----------------------------------------------------------------------

/*
const React = require('react');

const Redux = require('redux');

const ReactRedux = require('react-redux');

const reducer = (state, action) => {
  if (action.type === 'INC') {
    return state + 1;
  }
  else {
    return state;
  }
};

// logger :: Store => (Action -> Action) -> (Action -> Unit)
const logger = store => next => action => {
  console.group('logger')
  console.info('dispatching', action)
  let result = next(action)
  console.log('next state', store.getState())
  console.log('next');
  console.log('result', result);
  console.groupEnd('logger')
};

const vanillaPromise = store => next => action => {
  console.group('vanillaPromise');
  console.log(action);

  if (typeof action.then !== 'function') {
    return next(action)
  }

  const result = Promise.resolve(action).then(store.dispatch);

  console.groupEnd('vanillaPromise');

  return result;
};

// next(store.dispatch) :: Action -> Action
const thunk = store => next => action => {
  console.group('thunk');
  console.log(action);

  const result = typeof action === 'function'
    ? action(store.dispatch, store.getState)
    : next(action);

  console.groupEnd('thunk');

  return result;
}

// logger(api)(vanillaPromise(api)(thunk(api)(store.dispatch)))
// 
//const store = Redux.createStore(reducer, 0, Redux.applyMiddleware(
//  logger,
//  vanillaPromise,
//  thunk
//));
const store = Redux.createStore(reducer, 0, window.__REDUX_DEVTOOLS_EXTENSION__());

class App extends React.Component {
  constructor(props) {
    super(props);

    this.onClick = this.props.onClick.bind(this);
  }

  render() {
    return React.createElement('button', {
      onClick: this.onClick
    },
      'Test: ',
      this.props.value
    );
  }
}
*/

// ----------------------------------------------------------------------

const element = document.getElementById('app');

ReactDOM.render(App.main(), element);

/*
ReactDOM.render(
  React.createElement(ReactRedux.Provider, {
    store
  },  React.createElement(
    ReactRedux.connect(a => ({value: a}), dispatch => ({
      onClick: () => {
        dispatch({type: 'INC'});
      }
    }))(App)
  )),
  element
);

//const render = () => ReactDOM.render(React.createElement(App, {
//  value: store.getState(),
//  onClick: () => {
//    store.dispatch(Promise.resolve({
//      type: 'INC'
//    }));
//  }
//}), element);

//render();

//store.subscribe(render);
*/

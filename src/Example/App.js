'use strict';

exports.reduxDevtoolsExtensionEnhancer = !window.__REDUX_DEVTOOLS_EXTENSION__ ? function reduxDevtoolsExtensionEnhancer (a) {
  return a;
} : window.__REDUX_DEVTOOLS_EXTENSION__();

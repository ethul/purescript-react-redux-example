'use strict';

exports.reduxDevtoolsExtensionEnhancer_ = !window.__REDUX_DEVTOOLS_EXTENSION__ ? function(k){return k;} : window.__REDUX_DEVTOOLS_EXTENSION__();

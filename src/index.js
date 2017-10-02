'use strict';

const ReactDOM = require('react-dom');

const App = require('./Example/App.purs');

const element = document.getElementById('app');

ReactDOM.render(App.main(), element);

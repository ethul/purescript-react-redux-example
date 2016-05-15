'use strict';

var PurescriptWebpackPlugin = require('purescript-webpack-plugin');

var src = ['bower_components/purescript-*/src/**/*.purs', 'src/Example/**/*.purs'];

var ffi = ['bower_components/purescript-*/src/**/*.js', 'src/Example/**/*.js'];

var modulesDirectories = [
  'node_modules',
  'bower_components'
];

var purescriptWebpackPlugin = new PurescriptWebpackPlugin({
  src: src,
  ffi: ffi,
  bundle: false,
  psc: 'psa',
  pscArgs: {
    sourceMaps: false
  }
});

var config
  = { entry: './src/index'
    , debug: true
    , devtool: 'eval'
    , devServer: { contentBase: '.'
                 , port: 4008
                 , stats: 'errors-only'
                 }
    , output: { path: __dirname
              , pathinfo: true
              , filename: 'bundle.js'
              }
    , module: { loaders: [ { test: /\.purs$/
                           , loader: 'purs-loader'
                           }
                         ]
              }
    , resolve: { modulesDirectories: modulesDirectories
               , extensions: [ '', '.purs', '.js']
               }
    , plugins: [ purescriptWebpackPlugin ]
    }
    ;

module.exports = config;

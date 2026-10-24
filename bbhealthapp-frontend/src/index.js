import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import './items.scss';
import App from './App';
import * as serviceWorker from './serviceWorker';
import { Provider } from "react-redux";
import { PersistGate } from 'redux-persist/integration/react';
import { persistor, store } from './config/store';
import { LoadingView } from "./component/LoadingView";
import { BrowserRouter } from 'react-router-dom'; // Added official router

ReactDOM.render(
     <Provider store={store}>
          <PersistGate loading={<LoadingView/>} persistor={persistor}>
              {/* Wrapped with the official BrowserRouter for routing to work */}
              <BrowserRouter>
                  <App />
              </BrowserRouter>
          </PersistGate>
      </Provider>,
  document.getElementById('root')
);

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

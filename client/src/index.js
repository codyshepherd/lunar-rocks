'use strict';

import { Elm } from './Main.elm';

var authKey = "auth";
var flags = localStorage.getItem(authKey);

var app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: flags
});

app.ports.storeAuth.subscribe(function(auth) {

  // Remove username-token pair when user logs out, else update them
  if (auth === null) {
    localStorage.removeItem(authKey);
  } else {
    localStorage.setItem(authKey, JSON.stringify(auth));
  }

  // Report that the username-token pair was stored or removed
  setTimeout(function() { app.ports.onAuthStoreChange.send(auth); }, 0);
});

// Whenever localStorage changes, report it if necessary.
window.addEventListener("storage", function(event) {
  if (event.storageArea === localStorage && event.key === authKey) {
    console.log (event.newValue);
    app.ports.onAuthStoreChange.send(event.newValue);
  }
}, false);


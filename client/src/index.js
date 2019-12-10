"use strict";

import { Elm } from "./Main.elm";
import Amplify, { Auth } from "aws-amplify";
import { awsconfig } from "../amplify/aws-exports";
Amplify.configure(awsconfig);

Auth.currentSession()
  .then(session => {
    init({
      user: {
        username: session.accessToken.payload.username,
        token: session.accessToken.jwtToken
      }
    });
  })
  .catch(() => {
    init(null);
  });

const init = flags => {
  const app = Elm.Main.init({
    node: document.getElementById("root"),
    flags: flags
  });

  app.ports.cognitoRegister.subscribe(registration => {
    Auth.signUp({
      username: registration.username,
      password: registration.password,
      attributes: {
        email: registration.email
      },
      validationData: []
    })
      .then(() => {
        app.ports.onCognitoResponse.send({ response: "success" });
      })
      .catch(err => {
        app.ports.onCognitoResponse.send({
          response: "error",
          message: err.message
        });
      });
  });

  app.ports.cognitoConfirm.subscribe(confirmation => {
    Auth.confirmSignUp(confirmation.username, confirmation.code, {})
      .then(() => {
        app.ports.onCognitoResponse.send({ response: "success" });
      })
      .catch(err => {
        app.ports.onCognitoResponse.send({
          response: "error",
          message: err.message
        });
      });
  });

  app.ports.cognitoLogin.subscribe(creds => {
    Auth.signIn({
      username: creds.username,
      password: creds.password
    })
      .then(user => {
        app.ports.onAuthStoreChange.send({
          user: {
            username: user.username,
            token: user.signInUserSession.accessToken.jwtToken
          }
        });
      })
      .catch(err => {
        app.ports.onCognitoResponse.send({
          response: "error",
          message: err.message
        });
      });
  });

  app.ports.cognitoLogout.subscribe(() => {
    Auth.signOut()
      .then(() => {
        app.ports.onAuthStoreChange.send();
      })
      .catch(() => {});
  });

  // Whenever localStorage changes, report it to update all tabs.
  window.addEventListener(
    "storage",
    function(event) {
      if (event.storageArea === localStorage) {
        Auth.currentSession()
          .then(session => {
            app.ports.onAuthStoreChange.send({
              user: {
                username: session.accessToken.payload.username,
                token: session.accessToken.jwtToken
              }
            });
          })
          .catch(() => {
            app.ports.onAuthStoreChange.send();
          });
      }
    },
    false
  );
};

"use strict";

import { Elm } from "./Main.elm";
import { sine, square, triangle } from "../assets/svg-exports"; // regitser default avatars with parcel
import Amplify, { Auth } from "aws-amplify";
import { awsconfig } from "../aws/aws-exports";
Amplify.configure(awsconfig);

Auth.currentAuthenticatedUser()
  .then(user => {
    init({
      user: {
        token: user.signInUserSession.accessToken.jwtToken,
        account: {
          username: user.username,
          email: user.attributes.email
        }
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
            token: user.signInUserSession.accessToken.jwtToken,
            account: {
              username: user.username,
              email: user.attributes.email
            }
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

  app.ports.cognitoUpdatePassword.subscribe(passwords => {
    Auth.currentAuthenticatedUser()
      .then(user => {
        return Auth.changePassword(
          user,
          passwords.oldPassword,
          passwords.newPassword
        );
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

  app.ports.cognitoUpdateEmail.subscribe(email => {
    Auth.currentAuthenticatedUser()
      .then(user => {
        return Auth.updateUserAttributes(user, email);
      })
      .then(() => {
        app.ports.onCognitoResponse.send({ response: "success" });
      })
      .catch(err => {
        console.log(err);
        app.ports.onCognitoResponse.send({
          response: "error",
          message: err.message
        });
      });
  });

  app.ports.cognitoVerifyEmail.subscribe(code => {
    Auth.verifyCurrentUserAttributeSubmit("email", code)
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

  app.ports.cognitoForgotPassword.subscribe(username => {
    Auth.forgotPassword(username)
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

  app.ports.cognitoResetPassword.subscribe(reset => {
    Auth.forgotPasswordSubmit(
      reset.username,
      reset.confirmationCode,
      reset.newPassword
    )
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

  // Whenever localStorage changes, report it to update all tabs.
  window.addEventListener(
    "storage",
    function(event) {
      if (event.storageArea === localStorage) {
        Auth.currentAuthenticatedUser()
          .then(user => {
            app.ports.onAuthStoreChange.send({
              user: {
                token: user.signInUserSession.accessToken.jwtToken,
                account: {
                  username: user.username,
                  email: user.attributes.email
                }
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

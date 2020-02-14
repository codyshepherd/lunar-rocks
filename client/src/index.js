"use strict";

import { Elm } from "./Main.elm";
import { sine, square, triangle } from "../assets/svg-exports"; // regitser default avatars with parcel
import Amplify, { Auth, Storage } from "aws-amplify";
import { awsconfig } from "../aws/aws-exports";
Amplify.configure(awsconfig);

// window.LOG_LEVEL = "DEBUG";

// helper to convert missing attributes to nulls
const nullUndefOrVal = val => (val === undefined ? null : val);

async function getCurrentUser() {
  var accessToken = await Auth.currentAuthenticatedUser()
    .then(user => {
      return user.signInUserSession.accessToken.jwtToken;
    })
    .catch(() => {
      return null;
    });

  var user = await Auth.currentUserInfo()
    .then(user => {
      return user;
    })
    .catch(() => {
      return null;
    });

  if (accessToken !== null && user !== null) {
    return {
      user: {
        token: accessToken,
        account: {
          username: user.username,
          email: user.attributes.email
        },
        profile: {
          avatar: {
            url: nullUndefOrVal(user.attributes.picture),
            description: user.username + "'s avatar"
          },
          displayName: nullUndefOrVal(user.attributes.nickname),
          bio: nullUndefOrVal(user.attributes["custom:bio"]),
          location: nullUndefOrVal(user.attributes["custom:location"]),
          website: nullUndefOrVal(user.attributes.website)
        }
      }
    };
  } else {
    return null;
  }
}

// Auth.currentAuthenticatedUser()
//   .then(user => {
//     init({
//       user: {
//         token: user.signInUserSession.accessToken.jwtToken,
//         account: {
//           username: user.username,
//           email: user.attributes.email
//         },
//         profile: {
//           avatar: {
//             url: nullUndefOrVal(user.attributes.picture),
//             description: user.username + "'s avatar"
//           },
//           displayName: nullUndefOrVal(user.attributes.nickname),
//           bio: nullUndefOrVal(user.attributes["custom:bio"]),
//           location: nullUndefOrVal(user.attributes["custom:location"]),
//           website: nullUndefOrVal(user.attributes.website)
//         }
//       }
//     });
//   })
//   .catch(() => {
//     init(null);
//   });

// const init = flags => {
// const app = Elm.Main.init({
//   node: document.getElementById("root"),
//   flags: flags
// });

const init = async () => {
  const currentUser = await getCurrentUser();
  const app = Elm.Main.init({
    node: document.getElementById("root"),
    flags: currentUser
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
            },
            profile: {
              avatar: {
                url: nullUndefOrVal(user.attributes.picture),
                description: user.username + "'s avatar"
              },
              displayName: nullUndefOrVal(user.attributes.nickname),
              bio: nullUndefOrVal(user.attributes["custom:bio"]),
              location: nullUndefOrVal(user.attributes["custom:location"]),
              website: nullUndefOrVal(user.attributes.website)
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

  app.ports.cognitoUpdateDisplayName.subscribe(displayName => {
    Auth.currentAuthenticatedUser()
      .then(user => {
        return Auth.updateUserAttributes(user, displayName);
      })
      .then(async () => {
        // works, but refreshes the page wiping out the success message
        app.ports.onCognitoResponse.send({ response: "success" });
        const user = await getCurrentUser();
        app.ports.onAuthStoreChange.send(user);
      })
      .catch(err => {
        console.log(err);
        app.ports.onCognitoResponse.send({
          response: "error",
          message: err.message
        });
      });
  });

  app.ports.cognitoUpdateAbout.subscribe(about => {
    Auth.currentAuthenticatedUser()
      .then(user => {
        return Auth.updateUserAttributes(user, about);
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

  window.addEventListener(
    "storage",
    async function(event) {
      if (event.storageArea === localStorage) {
        const user = await getCurrentUser();

        // an ugly hack to avoid an async delayed, invalid user
        if (window.localStorage.length !== 0) {
          app.ports.onAuthStoreChange.send(user);
        } else {
          app.ports.onAuthStoreChange.send();
        }
      }
    },
    false
  );

  // Whenever localStorage changes, report it to update all tabs.
  // window.addEventListener(
  //   "storage",
  //   function(event) {
  //     if (event.storageArea === localStorage) {
  //       Auth.currentAuthenticatedUser()
  //         .then(user => {
  //           console.log(user);
  //           app.ports.onAuthStoreChange.send({
  //             user: {
  //               token: user.signInUserSession.accessToken.jwtToken,
  //               account: {
  //                 username: user.username,
  //                 email: user.attributes.email
  //               },
  //               profile: {
  //                 avatar: {
  //                   url: nullUndefOrVal(user.attributes.picture),
  //                   description: user.username + "'s avatar"
  //                 },
  //                 displayName: nullUndefOrVal(user.attributes.nickname),
  //                 bio: nullUndefOrVal(user.attributes["custom:bio"]),
  //                 location: nullUndefOrVal(user.attributes["custom:location"]),
  //                 website: nullUndefOrVal(user.attributes.website)
  //               }
  //             }
  //           });
  //         })
  //         .catch(() => {
  //           app.ports.onAuthStoreChange.send();
  //         });
  //     }
  //   },
  //   false
  // );
};

init();

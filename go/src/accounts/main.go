package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var db *Database

var Tokens map[string]jwt.Token
var tableNames = []string{"tokens", "registered"}

const schema = "registered_accounts"
const develKey = "sometypeofimportedsigningkey"

func main() {

	// get any cli options
	var credsFile string
	var listenPort string
	var logLevel string
	flag.StringVar(&credsFile, "creds", "psql_creds.rc",
		"File to find Postgres credentials")
	flag.StringVar(&listenPort, "port", "9000",
		"port for server to listen on")
	flag.StringVar(&logLevel, "log", "v",
		"Log Levels\nn: Errors only\nq: Info\nv: Debug\nvvv: Trace")
	flag.Parse()

	// set log level
	var ll log.Level
	switch logLevel {
	case "n":
		ll = log.ErrorLevel
	case "q":
		ll = log.InfoLevel
	case "v":
		ll = log.DebugLevel
	case "vvv":
		ll = log.TraceLevel
	}
	log.SetLevel(ll)
	dbName := "accounts"

	db = dbInit(credsFile, dbName, tableNames)
	defer db.Close()
	log.Info("Webserver start")
	log.Info("Lisening on port: " + listenPort)

	// instantiate the web router
	r := mux.NewRouter()

	// Handle calls to index and elm.js with same function
	r.HandleFunc("/register", registerHandle)
	r.HandleFunc("/login", signInHandle)

	// Serve and log
	if err := http.ListenAndServe(":"+listenPort, r); err != nil {
		log.Error(err)
		return
	}
}

func ErrorFail(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

func enableCors(w *http.ResponseWriter, req *http.Request) {
	log.Debug("enableCors called")
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST")
	(*w).Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length")
}

func signInHandle(w http.ResponseWriter, r *http.Request) {
	log.Debug("signInHandle called")
	log.Debug(r.Method)

	// Handle CORS
	enableCors(&w, r)
	if r.Method == "OPTIONS" {
		log.Info("Responding 200 to OPTIONS pre-flight Check")
		w.WriteHeader(200)
		return
	}

	// Read and unmarshal request body
	log.Debug(r)
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem reading info from the client."))
		return
	}

	defer r.Body.Close()
	var acct SignInAccount

	if err := json.Unmarshal(body, &acct); err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem parsing info from the client."))
		return
	}

	// Check the password against the stored hash
	match, err := db.ComparePasswordHashByUsername(acct.User.Username, acct.User.Password)
	if err != nil { // case: error
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem comparing the password."))
		return
	} else if !match { // case: no match
		log.Info(fmt.Sprintf("Incorrect Password on login attempt for user %s", acct.User.Username))
		w.WriteHeader(http.StatusForbidden)
		w.Write([]byte("Incorrect password or username."))
	} else { // case: match
		// get user id
		id, err := db.GetIdByUsername(acct.User.Username)
		if err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("There was a problem finding the user."))
			return
		}
		log.Info("Password hashes match")

		// generate and sign JWT
		expiry := time.Now().AddDate(0, 0, 21)
		claims := jwt.StandardClaims{
			Id:        id,
			Issuer:    "Devel",
			ExpiresAt: expiry.Unix(),
		}
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		tokString, err := token.SignedString([]byte(develKey))
		if err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("There was a problem generating a session token."))
			return
		}
		log.Debug(fmt.Sprintf("Token generated successfully: %s", tokString))

		// Store token in database along with type
		tokStruct := Token{
			TokenString:  tokString,
			Type:         Bigfoot,
			Valid:        true,
			Expires:      expiry,
			ForeignKeyID: id,
		}

		if err := db.StoreNewTokenForUser(&tokStruct); err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("There was a problem recording token data."))
			return
		}

		// return 200 + json
		w.Header().Set("Content-Type", "application/json")
		payload := ResponseAccount{
			User: ResponseUser{
				Username: acct.User.Username,
				Token:    tokString,
			},
		}
		bytes, err := json.Marshal(payload)
		if err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("There was a problem sending response data."))
			return
		}
		log.Debug("Payload marshaled successfully")

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, string(bytes))
		log.Debug("Registration OK response sent successfully")

	}
	log.Debug("SignInHandle finished")
	return
}

func registerHandle(w http.ResponseWriter, r *http.Request) {
	log.Debug("registerHandle called")
	log.Debug(r.Method)

	// Handle CORS
	enableCors(&w, r)
	if r.Method == "OPTIONS" {
		log.Info("Responding 200 to OPTIONS pre-flight Check")
		w.WriteHeader(200)
		return
	}

	// Read and unmarshal request data
	log.Debug(r)
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem reading info from the client."))
		return
	}

	defer r.Body.Close()
	var acct Account

	if err := json.Unmarshal(body, &acct); err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem parsing info from the client."))
		return
	}

	// Generate password hash and clear the plaintext pw
	hash, err := bcrypt.GenerateFromPassword([]byte(acct.User.Password), 0)
	acct.User.Password = ""
	if err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem handling the password."))
		return
	}

	log.Info(fmt.Sprintf("Received FormValues: %s, %s, %b", acct.User.Username,
		acct.User.Email, hash))

	// Store the new user
	id, err := db.InsertNewUser(&acct, hash)
	if err != nil {
		log.Error(err)
		droperr := db.DeleteByID(id)
		if droperr != nil {
			log.Error(droperr)
		}
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem storing the new user."))
		return
	}

	// generate and sign JWT
	expiry := time.Now().AddDate(0, 0, 21)
	claims := jwt.StandardClaims{
		Id:        id,
		Issuer:    "Devel",
		ExpiresAt: expiry.Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokString, err := token.SignedString([]byte(develKey))
	if err != nil {
		log.Error(err)
		droperr := db.DeleteByID(id)
		if droperr != nil {
			log.Error(droperr)
		}
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem generating a session token."))
		return
	}
	log.Debug(fmt.Sprintf("Token generated successfully: %s", tokString))

	// Store token in database along with type
	tokStruct := Token{
		TokenString:  tokString,
		Type:         Bigfoot,
		Valid:        true,
		Expires:      expiry,
		ForeignKeyID: id,
	}

	if err := db.StoreNewTokenForUser(&tokStruct); err != nil {
		log.Error(err)
		droperr := db.DeleteByID(id)
		if droperr != nil {
			log.Error(droperr)
		}
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem recording token data."))
		return
	}

	// return 200 + json
	w.Header().Set("Content-Type", "application/json")
	payload := ResponseAccount{
		User: ResponseUser{
			Username: acct.User.Username,
			Token:    tokString,
		},
	}
	bytes, err := json.Marshal(payload)
	if err != nil {
		log.Error(err)
		droperr := db.DeleteByID(id)
		if droperr != nil {
			log.Error(droperr)
		}
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("There was a problem sending response data."))
		return
	}
	log.Debug("Payload marshaled successfully")

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, string(bytes))
	log.Debug("Registration OK response sent successfully")

}

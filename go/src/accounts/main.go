package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"

	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB

const registeredTableName = "registered"
const schema = "registered_accounts"

var idCounter = 0

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
	db = dbInit(credsFile, dbName, registeredTableName)
	defer db.Close()
	log.Info("Webserver start")
	log.Info("Lisening on port: " + listenPort)

	// instantiate the web router
	r := mux.NewRouter()

	// Handle calls to index and elm.js with same function
	// r.HandleFunc("/register", registerHandle).Methods("POST")
	r.HandleFunc("/register", registerHandle)

	// Serve and log
	err := http.ListenAndServe(":"+listenPort, r)

	check(err)
}

func check(e error) {
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

func dbInit(credsFile string, dbName string, tableName string) *sql.DB {
	// open the creds file and read contents
	prefix := "^PSQLUSER=.*\n"
	prefixlen := 9
	pwprefix := "PSQLPW=.*"
	pwprefixlen := 7

	f, err := ioutil.ReadFile(credsFile)
	check(err)
	fileStr := string(f)

	// use regex to find the username & pw
	re := regexp.MustCompile(prefix)
	str := re.FindString(fileStr)
	user := string(str[prefixlen:])

	re = regexp.MustCompile(pwprefix)
	str = re.FindString(fileStr)
	pw := string(str[pwprefixlen:])

	// connect to postgres
	connStr := fmt.Sprintf("host=localhost port=5433 dbname=%s user=%s password=%s sslmode=disable",
		dbName, user, pw)
	db, err := sql.Open("postgres", connStr) // This function does jack, so we need to Ping it
	err = db.Ping()
	check(err)
	log.Debug("DB opened")

	// Check if our DB exists
	rows, err := db.Query(`
		SELECT EXISTS(
 			SELECT datname FROM pg_catalog.pg_database WHERE lower(datname) = lower($1)
		);`, dbName)
	check(err)

	if rows == nil {
		log.Panic(fmt.Sprintf("Database %s not found!"))
	} else {
		log.Info("Found DB ", dbName)
	}

	// Check if our schema.table exists
	combined := fmt.Sprintf("%s.%s", schema, tableName)
	query := fmt.Sprintf("SELECT * FROM %s;", combined)
	log.Debug(query)
	rows, err = db.Query(query)
	check(err)

	if rows == nil {
		log.Panic("'registered' table does not exist!")
	} else {
		log.Debug(fmt.Sprintf("Table %s found, not creating.", tableName))
	}
	log.Info("Connect to postgres successful")
	return db
}

func registerHandle(w http.ResponseWriter, r *http.Request) {
	log.Debug("registerHandle called")
	log.Debug(r.Method)

	enableCors(&w, r)
	if r.Method == "OPTIONS" {
		log.Info("Responding 200 to OPTIONS pre-flight check")
		w.WriteHeader(200)
		return
	}

	log.Debug(r)
	body, err := ioutil.ReadAll(r.Body)
	check(err)
	defer r.Body.Close()
	var acct Account

	err = json.Unmarshal(body, &acct)
	check(err)
	hash, err := bcrypt.GenerateFromPassword([]byte(acct.User.Password), 0)
	check(err)

	log.Info(fmt.Sprintf("Received FormValues: %s, %s, %s, %b", acct.User.Username,
		acct.User.Email, hash))

	// TODO: See if the user is in the DB first

	query := fmt.Sprintf(`
	INSERT INTO %s.registered (id, username, email, passhash)
	VALUES ($1, $2, $3, $4)`, schema)

	_, err = db.Exec(query,
		idCounter,
		acct.User.Username,
		acct.User.Email,
		hash)
	check(err)
	idCounter += 1 // TODO: change this to a uuid
}

package main

import (
	"database/sql"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"

	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

var db *sql.DB

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
	db = dbInit(credsFile)
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
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST")
	(*w).Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length")
}

func dbInit(credsFile string) *sql.DB {
	// open the creds file and read contents
	prefix := "PSQLUSER=.*"
	f, err := ioutil.ReadFile(credsFile)
	check(err)
	fileStr := string(f)
	// use regex to find the username
	re := regexp.MustCompile(prefix)
	str := re.FindString(fileStr)
	fmt.Println(str)
	user := str[len(prefix):]
	// connect to postgres
	connStr := fmt.Sprintf("user=%s dbname=accounts sslmode=verify-full", user)
	db, err := sql.Open("postgres", connStr)
	check(err)
	tables, err := db.Query("show tables")
	if tables == nil {
		db.Query(`create table registered (
			username varchar(255),
			email varchar(255),
			passHash varchar(255)
		)`)
	}
	log.Info("Connect to postgres successful")
	return db
}

func registerHandle(w http.ResponseWriter, r *http.Request) {
	log.Info("registerHandle called")
	log.Info(r.Method)

	enableCors(&w, r)
	if r.Method == "OPTIONS" {
		return
	}

	err := r.ParseForm()
	check(err)
	user := r.FormValue("user")
	email := r.FormValue("email")
	pw := r.FormValue("password")
	log.Info(user, email, pw)
	db.Query(fmt.Sprintf("insert into registered (%s, %s, %s)", user, email, pw))
}

package main

import (
	"flag"

	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	"net/http"
)

func main() {

	// get any cli options
	var listenPort string
	var logLevel string
	flag.StringVar(&listenPort, "port", "1025",
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
	log.Info("Webserver start")
	log.Info("Lisening on port: " + listenPort)

	// instantiate the web router
	r := mux.NewRouter()

	// Handle calls to index and elm.js with same function
	r.HandleFunc("/", rootHandler)
	r.HandleFunc("/elm.js", rootHandler)
	r.HandleFunc("/assets/favicon.ico", rootHandler)

	// Serve and log
	err := http.ListenAndServe(":"+listenPort, r)

	if err != nil {
		log.Fatal("ListenandServe: ", err)
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	file := r.URL.Path
	if file == "/" {
		file = "/index.html"
	}
	log.Debug("Requested: " + file)
	http.ServeFile(w, r, "../client/build"+file)
}

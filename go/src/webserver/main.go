package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	"net/http"
)

func main() {

	// get date
	t := time.Now()
	string_t := t.Format("20060102150405") // format in yyyymMMddHHmmss
	default_logpath := "/var/log/webserver" + string_t + ".log"

	// get any cli options
	var listenPort string
	var logLevel string
	var printLogs bool
	flag.StringVar(&listenPort, "port", "1025",
		"port for server to listen on")
	flag.StringVar(&logLevel, "log", "v",
		"Log Levels\nn: Errors only\nq: Info\nv: Debug\nvvv: Trace")
	flag.BoolVar(&printLogs, "print-logs", false,
		"Whether to print logs (as opposed to logging to file)")
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

	if !printLogs {
		// open a file
		f, err := os.OpenFile(default_logpath,
			os.O_APPEND|os.O_CREATE|os.O_RDWR, 0666)
		if err != nil {
			fmt.Println("error opening log file: %v", err)
		}
		// don't forget to close it
		defer f.Close()
		// Log as JSON instead of the default ASCII formatter.
		log.SetFormatter(&log.JSONFormatter{})
		// Output to stderr instead of stdout, could also be a file.
		log.SetOutput(f)
	}

	log.SetLevel(ll)
	log.Info("Webserver start")
	log.Info("Lisening on port: " + listenPort)

	log.Debug("Contents of root dir:")
	files, _ := ioutil.ReadDir("./")
	for _, f := range files {
		log.Debug(f.Name())
	}

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

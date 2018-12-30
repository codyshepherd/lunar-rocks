package main

import (
	// "fmt"

	log "github.com/sirupsen/logrus"

	"github.com/gorilla/mux"
	"net/http"
)

func main() {
	log.Info("Webserver start")

	// instantiate the web router
	r := mux.NewRouter()
	r.Schemes("https")

	// default page is the static login/landing page
	r.Handle("/", http.FileServer(http.Dir("./views/")))
	// find static assets
	r.PathPrefix("/static/").Handler(http.StripPrefix("/static/",
		http.FileServer(http.Dir("./static/"))))

	// serve HTTPS on port 443
	err := http.ListenAndServeTLS(":443", "server.crt", "server.key", r)

	if err != nil {
		log.Fatal("ListenandServeTLS: ", err)
	}
}

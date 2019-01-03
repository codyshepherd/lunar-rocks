package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
	"net/http"
)

func main() {
	router := mux.NewRouter()
	r.Schemes("https")

	// Routes
	r.HandleFunc("/accounts", GetAccounts).Methods("GET")
	r.HandleFunc("/accounts/{id}", GetAccount).Methods("GET")
	r.HandleFunc("/accounts/{id}", CreateAccount).Methods("POST")
	r.HandleFunc("/accounts/{id}", DeleteAccount).Methods("DELETE")

	// serve HTTPS on port 443
	err := http.ListenAndServeTLS(":443", "server.crt", "server.key", r)

	if err != nil {
		log.Fatal("ListenandServeTLS: ", err)
	}
}

func GetAccounts(w http.ResponseWriter, r *http.Request)   {}
func GetAccount(w http.ResponseWriter, r *http.Request)    {}
func CreateAccount(w http.ResponseWriter, r *http.Request) {}
func DeleteAccount(w http.ResponseWriter, r *http.Request) {}

package main

import (
	"net/http"
	"os"
	"sync"

	"github.com/gorilla/websocket"

	log "github.com/sirupsen/logrus"
)

const (
	privateKeyFileName  = "private.pem"
	publicKeyFileName   = "public.pem"
	certificateFileName = "cert.pem"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func serveWs(w http.ResponseWriter, r *http.Request) {
	log.Debug("serveWs started")
	conn, err := upgrader.Upgrade(w, r, nil)
	debugCheckErr(err)

	client := &Client{conn: conn, send: make(chan []byte, 1024)}

	//go client.writeWorker(conn)
	go client.run()
}

func debugCheckErr(err error) {
	// from gist documented in genKeyPairFiles()
	if err != nil {
		log.Fatal("Fatal error ", err.Error())
		panic()
	}
}

func main() {
	log.SetOutput(os.Stdout)
	log.SetLevel(log.DebugLevel)
	log.Debug("Main started")

	var wg sync.WaitGroup
	wg.Add(1)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		serveWs(w, r)
	})
	err := http.ListenAndServeTLS("localhost:8795", certificateFileName, privateKeyFileName, nil)
	debugCheckErr(err)
}

package main

type session struct {
    forward chan []byte     // holds incoming messages that should be forwarded to other clients
}

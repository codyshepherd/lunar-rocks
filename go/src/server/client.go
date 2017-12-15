package main

import (
    "fmt"
    "time"
    "log"
    "bytes"
    "github.com/gorilla/websocket"
)

const (
    writeWait = 10 * time.Second

    pongWait = 60 * time.Second

    maxMessageSize = 1024
)

var (
    newline = []byte{'\n'}
    space   = []byte{' '}
)

type Client struct {
    // socket is the websocket for this client
    conn *websocket.Conn

    // send is a channel on which messages are sent
    send chan []byte

    // session is the session this client is in
    //session *session
}

func (c *Client) readWorker() {
    defer c.conn.Close()

    c.conn.SetReadLimit(maxMessageSize)
    c.conn.SetReadDeadline(time.Now().Add(pongWait))
    c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
    for {
        _, message, err := c.conn.ReadMessage()
        if err != nil {
            if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway) {
                log.Printf("error: %v", err)
            }
            break
        }
        message = bytes.TrimSpace(bytes.Replace(message, newline, space, -1))
        fmt.Println(message)
    }
}
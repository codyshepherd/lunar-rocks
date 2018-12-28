package main

import (
	"bytes"
	"fmt"
	"time"

	"github.com/gorilla/websocket"
	log "github.com/sirupsen/logrus"
)

const (
	writeWait = 10 * time.Second

	pongWait = 60 * time.Second

	maxMessageSize = 1024

	// dispatchTable is a map (dict) of ints to (anonymous) functions that take maps of ints to
	// arbitrary data types, and return booleans
	/*dispatchTable = map[int]func(*Client, map[int]interface{})bool{
	    112: func(c *Client, x map[int]interface{}) {
	        return c.handle112(x)
	    }
	}*/
)

var (
	newline       = []byte{'\n'}
	space         = []byte{' '}
	dispatchTable = map[int]func(*Client, map[int]interface{}) bool{
		112: func(c *Client, x map[int]interface{}) bool {
			return c.handle112(x)
		},
	}
)

type clientID string
type userType int
type token []byte

const (
    Registered userType = iota //iota is a successive untyped integer constant
    Anonymous
    // implicit repetition of last non-empty expression list
)

type Client struct {
	// The websocket for this client
	conn *websocket.Conn

	// where messages to be sent to the remote client get put
    send chan []byte
    
    // where messages received from remote client get put
    recv chan []byte

    // The unique ID assigned to the user: username or nickname
    id clientID

    // Device hardware ID
    devID string

    // Device Description
    devDesc string

    // The type of user this client corresponds to
    type userType

	// the Roster object that tracks active users
    // roster *Roster
    
    // Allows the client to integrate timed events (timeout checking) into `select` operation
    time chan Time

    // The token in use by this client
    tok token
}

func (c *Client) run() {
	defer c.conn.Close()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	for {
        select {
		case _, msg, err := c.conn.ReadMessage()
            if err != nil {
                if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway) {
                    // handle based on client type
                    log.Error("error: %v", err)
                }
                break
            }
            // check token validity, authenticate message, put valid message on c.recv channel

            // check token validity
                // check for token and Digest being present: 
                    // if yes, lookup stored token, assert validity, compare w/ presented token; 
                    // if not, check  message type; 
                        // if 112, call `handle_112()`
                        // if not 112, return message 114: Error; close connection

            // authenticate message
                // compute HMAC digest of message (minus Token and Digest fields) using token as key
                // compare computed HMAC with HMAC provided in message
                    // if digests match, continue
                    // if not, return message 114: Error; close connection

            // Put message on recv channel
        case msg := <- c.recv
            // parse and handle information
                // get message ID
                // call appropriate handler function for message ID
                // put any response information on send channel
        case msg := <- c.send
            // send info out on connection
        case time := <- c.time
            // check for timeout as applicable and update validity of token
        }
    }
}

package main

import (
	"encoding/json"

	log "github.com/sirupsen/logrus"
)

type fn func(*Client, Message)

var dispatchTable = map[int]fn {
	112: (*Client).handle_112,
}

type clientID string

type Client struct {
	recv chan []byte

	send chan []byte

	idKey clientID

	username string

	pw []byte

	roster *Roster

	anon bool

	browserIdKey browserID

}

func (c *Client) run() {
	log.Debug(string(c.idKey[:3]) + " run() started")
	for {
		select {
		case txt := <-c.recv:
			log.Debug(string(c.idKey[:3]) + "received text")
			var msg Message
			json.Unmarshal(txt, &msg)
			msgId := msg.MessageID
			dispatchTable[msgId](c, msg)
		case txt := <-c.send:
			log.Debug(string(c.idKey[:3]) + "sending text", txt)
		}
	}
}

func (c *Client) handle_112(msg Message) {
	log.Debug("112_handler started")

	var creds Credentials
	p := msg.Payload.(map[string]interface{})
	creds.Username = p["Username"].(string)
	creds.Hash = p["Hash"].(string)

	log.Debug(msg.SourceID, msg.MessageID, creds.Username)

	sid := msg.SourceID

	//log.Debug(sid, creds.Username, creds.Hash)

	//If Credentials portion of message exists, validate and return username as nick
	//Otherwise,
}

//var return_phrases = [...]string{"JSON string from Client"}

//type clientID string

/*
func (c *Client) readWorker() {
	for msg := range c.recv {
		log.Debug("Client " + string(c.cid) + " :: received " + string(msg))
	}
}

func (c *Client) writerWorker() {
	for msg := range c.send {
		c.browser.recv <- "Message from " + string(c.cid) + " :: " + msg
	}
}
*/

/*
func (c *Client) testSend(msg string) {
	c.browser.recv <- c.createSignedString(msg)
}

func (c *Client) createSignedString(msg string) string {
	//msg := "Pretend this is a JSON string"
	claims := MyCustomClaims{
		msg,
		jwt.StandardClaims{
			//ExpiresAt: 15000,
			Issuer: "test",
		},
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	if ss, err := tok.SignedString([]byte(c.cid)); err == nil {
		return ss
	} else {
		log.Debug("ERROR: ", err)
		return "error"
	}
}

func (c *Client) parseValidateString(msg string) string {
	tok, err := jwt.Parse(msg, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}

		return []byte(c.browser.bid), nil
	})

	if claims, ok := tok.Claims.(jwt.MapClaims); ok && tok.Valid {
		return claims["msg"].(string)
	} else {
		log.Debug("ERROR: ", err)
		return "error"
	}
}

func (c *Client) run() {
	log.Debug(string(c.cid[:3]) + " run() started")
	for {
		select {
		case msg := <-c.recv:
			validMsg := c.parseValidateString(msg)
			log.Debug("Client " + string(c.cid[:3]) + " received & parsed " + string(validMsg))
			index := rand.Int() % len(return_phrases)
			c.send <- return_phrases[index]
		case msg := <-c.send:
			signedMsg := c.createSignedString(msg)
			log.Debug("Client " + string(c.cid[:3]) + " sending signed message: " + string(msg))
			c.browser.recv <- signedMsg
		}
	}
}
*/

/*
func (c *Client) readWorker() {
	for msg := range c.recv {
		log.Debug("Client " + string(c.cid) + " :: received " + string(msg))
	}
}

func (c *Client) writerWorker() {
	for msg := range c.send {
		c.browser.recv <- "Message from " + string(c.cid) + " :: " + msg
	}
}
*/

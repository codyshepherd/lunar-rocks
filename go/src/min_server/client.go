package main

import (
	"fmt"
	"math/rand"

	jwt "github.com/dgrijalva/jwt-go"
)

var return_phrases = [...]string{"JSON string from Client"}

type clientID string

type Client struct {
	recv chan string

	send chan string

	cid clientID

	roster *Roster

	browser *Browser
}

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
		fmt.Println("ERROR: ", err)
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
		fmt.Println("ERROR: ", err)
		return "error"
	}
}

func (c *Client) run() {
	fmt.Println(string(c.cid[:3]) + " run() started")
	for {
		select {
		case msg := <-c.recv:
			validMsg := c.parseValidateString(msg)
			fmt.Println("Client " + string(c.cid[:3]) + " received & parsed " + string(validMsg))
			index := rand.Int() % len(return_phrases)
			c.send <- return_phrases[index]
		case msg := <-c.send:
			signedMsg := c.createSignedString(msg)
			fmt.Println("Client " + string(c.cid[:3]) + " sending signed message: " + string(msg))
			c.browser.recv <- signedMsg
		}
	}
}

/*
func (c *Client) readWorker() {
	for msg := range c.recv {
		fmt.Println("Client " + string(c.cid) + " :: received " + string(msg))
	}
}

func (c *Client) writerWorker() {
	for msg := range c.send {
		c.browser.recv <- "Message from " + string(c.cid) + " :: " + msg
	}
}
*/

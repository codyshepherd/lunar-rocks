package main

import (
	"fmt"
	"math/rand"
)

var return_phrases = [...]string{"reply", "in", "a", "random", "way", "just", "to", "see"}

type clientID string

type Client struct {
	recv chan string

	send chan string

	cid clientID

	roster *Roster

	browser *Browser
}

func (c *Client) testSend(msg string) {
	c.browser.recv <- msg
}

func (c *Client) run() {
	fmt.Println(string(c.cid[:3]) + " run() started")
	for {
		select {
		case msg := <-c.recv:
			fmt.Println("Client " + string(c.cid[:3]) + " :: received " + string(msg))
			index := rand.Int() % len(return_phrases)
			c.send <- return_phrases[index]
		case msg := <-c.send:
			c.browser.recv <- "Message from " + string(c.cid[:3]) + " :: " + msg
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

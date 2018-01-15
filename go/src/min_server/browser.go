package main

import "fmt"

type browserID string

type Browser struct {
	recv chan string

	send chan string

	client *Client

	bid browserID
}

func (b *Browser) testSend(msg string) {
	//b.client.recv <- msg
	b.send <- msg
}

func (b *Browser) run() {
	fmt.Println("Browser.run() started")
	for {
		select {
		case msg := <-b.recv:
			fmt.Println("Browser " + string(b.bid[:3]) + " :: received: " + string(msg))
		case msg := <-b.send:
			b.client.recv <- "Message from " + string(b.bid[:3]) + " :: " + msg
		}
	}
}

/*
func (b *Browser) readWorker() {
	for msg := range b.recv {
		fmt.Println("Browser " + string(b.bid) + " :: received: " + string(msg))
	}
}

func (b *Browser) writeWorker() {
	for msg := range b.send {
		b.client.recv <- "Message from " + string(b.bid) + " :: " + msg
	}
}
*/

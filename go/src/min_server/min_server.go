package main

import (
	"fmt"
	"math/rand"
	"sync"

	"github.com/google/uuid"
)

var phrases = [...]string{"these", "should", "be", "random", "strings", "for", "testing"}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)

	browsers := make([]*Browser, 10)
	cids := make([]clientID, 10)

	roster := &Roster{join: make(chan *Client, 1024), leave: make(chan *Client, 1024), clients: make(map[clientID]*Client), users: make(map[browserID]clientID), tokens: make(map[userID]string), secret: "secret"}
	go roster.run(wg)

	fmt.Println("Checkpoint 1")
	for i := 0; i < 10; i++ {
		fmt.Println("Checkpoint ", i)
		cid, _ := uuid.NewRandom()
		client := &Client{recv: make(chan string, 1024), send: make(chan string, 1024), cid: clientID(cid.String()), roster: roster}
		cids[i] = client.cid
		bid, _ := uuid.NewRandom()
		browser := &Browser{recv: make(chan string, 1024), send: make(chan string, 1024), client: client, bid: browserID(bid.String())}
		browsers[i] = browser
		client.browser = browser
		roster.join <- client
		//defer roster.kick(client.cid)

		go client.run()
		go browser.run()
	}

	fmt.Println("Checkpoint 2")
	for i := 0; i < len(phrases); i++ {
		index := rand.Int() % 10
		b := browsers[index]
		b.testSend(phrases[i])
	}

	fmt.Println("Checkpoint 3")
	for roster.usersActive() {
		for i := range cids {
			roster.kick(cids[i])
		}
	}

	wg.Wait()
}

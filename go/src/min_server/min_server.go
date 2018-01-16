package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"sync"
	"time"

	"github.com/google/uuid"
)

var phrases = [...]string{"JSON string from Browser"}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)

	browsers := make([]*Browser, 10)
	cids := make([]clientID, 10)

	roster := &Roster{join: make(chan *Client, 1024), leave: make(chan *Client, 1024), clients: make(map[clientID]*Client), users: make(map[browserID]clientID), tokens: make(map[userID]string)}
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
	for i := 0; i < 10; i++ {
		index := rand.Int() % len(phrases)
		b := browsers[i]
		b.testSend(phrases[index])
	}

	fmt.Println("Checkpoint 3")
	/*
		for roster.usersActive() {
			for i := range cids {
				roster.kick(cids[i])
			}
		}
	*/

	for {
		if roster.usersActive() {
			for i := range cids {
				roster.kick(cids[i])
			}
		} else {
			fmt.Println("No users Active")
		}
		fmt.Println(strconv.FormatBool(roster.usersActive()))
		fmt.Println(len(roster.clients))
		time.Sleep(1 * time.Second)
	}
	wg.Wait()
}

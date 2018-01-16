package main

import (
	"fmt"
	"strconv"
	"sync"
)

type userID string

type Roster struct {
	join chan *Client

	leave chan *Client

	clients map[clientID]*Client

	users map[browserID]clientID

	tokens map[userID]string
}

func (r *Roster) run(wg sync.WaitGroup) {
	defer wg.Done()
	fmt.Println("Roster.run() started.")
	for {
		select {
		case client := <-r.join:
			fmt.Println("roster registering client " + string(client.cid))
			r.clients[client.cid] = client
			r.users[client.browser.bid] = client.cid
			fmt.Println(strconv.Itoa(len(r.clients)) + " total clients")
		case client := <-r.leave:
			fmt.Println("roster deleting client " + string(client.cid))
			delete(r.clients, client.cid)
			delete(r.users, client.browser.bid)
			fmt.Println(strconv.Itoa(len(r.clients)) + " total clients")
		}
	}
}

func (r *Roster) kick(cid clientID) {
	if client, ok := r.clients[cid]; ok {
		r.leave <- client
		fmt.Println("roster kicking " + string(cid[:3]) + " for total of " + strconv.Itoa(len(r.clients)) + " clients.")
	}
}

func (r *Roster) usersActive() bool {
	if len(r.clients) == 0 {
		return false
	}
	return true
}

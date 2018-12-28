package main

import (
	"strconv"
	"sync"

	log "github.com/sirupsen/logrus"
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
	//defer wg.Done()
	log.Debug("Roster.run() started.")
	for {
		select {
		case client := <-r.join:
			log.Debug("roster registering client " + string(client.idKey))
			r.clients[client.idKey] = client
			r.users[client.browserIdKey] = client.idKey
			log.Debug(strconv.Itoa(len(r.clients)) + " total clients")
		case client := <-r.leave:
			log.Debug("roster deleting client " + string(client.idKey))
			delete(r.clients, client.idKey)
			delete(r.users, client.browserIdKey)
			log.Debug(strconv.Itoa(len(r.clients)) + " total clients")
		}
	}
}

func (r *Roster) kick(idKey clientID) {
	if client, ok := r.clients[idKey]; ok {
		r.leave <- client
		log.Debug("roster kicking " + string(idKey[:3]) + " for total of " + strconv.Itoa(len(r.clients)) + " clients.")
	}
}

func (r *Roster) usersActive() bool {
	if len(r.clients) == 0 {
		return false
	}
	return true
}

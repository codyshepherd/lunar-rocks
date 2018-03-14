package main

import (
	"encoding/json"

	log "github.com/sirupsen/logrus"
)

func handle_112(txt []byte, roster *Roster) {
	/*
		Assumptions from caller:
			type checked for Message struct type
	*/
	log.Debug("112_handler started")

	var msg Message
	json.Unmarshal(txt, &msg)

	log.Debug(msg.SourceID, msg.MessageID, msg.Payload)

	sid := msg.SourceID
	creds := msg.Payload

	log.Debug(sid, creds)
	//If Credentials portion of message exists, validate and return username as nick
	//Otherwise,
}

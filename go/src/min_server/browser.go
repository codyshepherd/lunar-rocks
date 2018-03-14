package main

import (
	"encoding/json"

	crypto "golang.org/x/crypto/argon2"
)

type browserID string

type Browser struct {
	//recv chan string
	recv chan []byte // byte array channels are required for sending json-marshalled data

	//send chan string
	send chan []byte

	client *Client

	//bid browserID
	idKey browserID

	secret string

	salt []byte
}

func (b *Browser) startSend(number int) {
	hash := crypto.Key([]byte(b.secret), b.salt, 3, 32*1024, 4, 256)
	startmsg := Message{0, 112, Credentials{"uname0", hash}}
	m, _ := json.Marshal(startmsg)
	b.send <- m
}

//type browserID string

/*
func (b *Browser) testSend(msg string) {
	//b.client.recv <- msg
	b.send <- msg
}
*/

/*
func (b *Browser) createSignedString(msg string) string {
	//msg := "Pretend this is a JSON string"
	claims := MyCustomClaims{
		msg,
		jwt.StandardClaims{
			//ExpiresAt: 15000,
			Issuer: "test",
		},
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	if ss, err := tok.SignedString([]byte(b.bid)); err == nil {
		return ss
	} else {
		fmt.Println("B ERROR: ", err)
		return "error"
	}
}

func (b *Browser) parseValidateString(msg string) string {
	tok, err := jwt.Parse(msg, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}

		return []byte(b.client.cid), nil
	})

	if claims, ok := tok.Claims.(jwt.MapClaims); ok && tok.Valid {
		return claims["msg"].(string)
	} else {
		fmt.Println("B ERROR: ", err)
		return "error"
	}
}

func (b *Browser) run() {
	fmt.Println("Browser.run() started")
	for {
		select {
		case msg := <-b.recv:
			validMsg := b.parseValidateString(msg)
			fmt.Println("Browser " + string(b.bid[:3]) + " received & parsed " + string(validMsg))
			//index := rand.Int() % len(return_phrases)
			//b.send <- return_phrases[index]
		case msg := <-b.send:
			signedMsg := b.createSignedString(msg)
			fmt.Println("Browser " + string(b.bid[:3]) + " sending signed message: " + string(msg))
			b.client.recv <- signedMsg
		}
	}
}
*/

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

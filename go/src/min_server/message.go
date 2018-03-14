package main

type Message struct {
	SourceID  int
	MessageID int
	Payload   interface{} //Another struct
}

type Session struct {
	SessionID int
	Clients   []string
	Tempo     int
	Board     []TrackObject
}

type TrackObject struct {
	TrackID    int
	ClientID   string
	Nickname   string
	Instrument string
	Grid       [][]int
}

type Credentials struct {
	Username string
	Hash     []byte
}

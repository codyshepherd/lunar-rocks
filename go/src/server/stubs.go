// object and function stubs
package main 

//-------------------------------------------------------------------------------------------------
//										CLIENT
//-------------------------------------------------------------------------------------------------

// The Client object represents the object with which we are communicating - the remote 
// device that enables the User to connect with us. 
type Client struct {
    // socket is the websocket for this client
    conn *websocket.Conn

    // send is a channel on which messages are sent
	send chan []byte
	
	// the clientID is a unique uuid generated by the server and stored by the web client
	clientID string
}

// The function services the Client's `send` channel
func (c *Client) readWorker() {}

//-------------------------------------------------------------------------------------------------
//										ROSTER
//-------------------------------------------------------------------------------------------------

// The Roster registers user information in the Database, and creates & destroys 
// Sessions as they are created and abandoned. 
type Roster struct {

	// join is a channel for Clients wishing to join the roster
	join chan *Client

	// leave is a channel for clients wishing to leave the roster
	leave chan *Client
	
	// clients holds all clients currently active
	clients map[clientID]*Client

	// users holds mapping of users to clients
	users map[userID]clientID

	//TODO: logging
}

// This function should be a `select`-style serialized handling of requests in each
// channel
func (r *Roster) run() {} 


//-------------------------------------------------------------------------------------------------
//										USER
//-------------------------------------------------------------------------------------------------

// The User represents an organizational unit of content in Lunar Rocks -- it stores metadata 
// necessary for constructing/displaying user Profiles, and serves as a key by which to identify a
// user role, their activity, and any content marked for long term storage (saving)
// Types Standard and Anon are types that implement this interface
type User interface {

	// human readable name
	username() string

	// unique uuid
	userID() string

	// a list of trackIDs that identifies which, if any, Tracks this user has saved in LTS
	savedTracks() []trackID

	// a list of sessionIDs that tracks which sessions this user is currently active in
	activeSessions() []sessionID

	// defines the role of the user
	const role()

	// dunno if we want to demand this function be implemented?
	readWorker() nil
	//edits chan int
}

type Standard struct {}

type Anon struct {}

// This function services the User's `edits` channel
func (u *User) readWorker() {}

//-------------------------------------------------------------------------------------------------
//										SESSION
//-------------------------------------------------------------------------------------------------

// A Session manages its own communications to and from its connected Clients
type Session struct {
	
	// channel that holds incoming messages that should be forwarded to other users
	forward chan []byte

	// channel for sending requests to session
	request chan *User

	// all users currently in session
	users map[userID]*User

	// tracks active in session
	tracks map[trackID]*Track
}

// services Session's channels
func (s *Session) readWorker() {}

//-------------------------------------------------------------------------------------------------
//										TRACK
//-------------------------------------------------------------------------------------------------

// A Track encapsulates the state necessary to construct a web audio track
type Track struct {

	// the uuid identifying this track
	const trackID string

	// The 2D array that specifies which tones are enabled on which beat
	grid [][]int

	// instrument type
	instrument

	// owner of this track
	owner userID
}

// leaving out changeInstrument() and changeOwner() for now because they are presumably trivial
// for the session to do themselves and do not need additional abstraction

// updates the internal grid state of this track
func (t *Track) updateGrid(newgrid [][]int) {}

func (t *Track) export() string {}


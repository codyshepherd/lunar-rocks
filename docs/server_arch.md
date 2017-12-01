# Server Architecture
v1.0

## Requirements
### Functional
 - [x] Accept Client Connections
 - [x] Handle multiple clients
 - [x] Client create session
 - [x] Client list all sessions
 - [x] Client join a session
 - [x] Client leave a session
 - [x] Client list members of a session
 - [x] Client send messages to a session
 - [x] Client join multiple sessions
 - [x] Client send distinct messages to multiple selected sessions
 - [x] Client disconnect
 - [x] Server kick client
 - [x] Handle client crashes
 
 ### Nonfunctional
 
 - [x] Graceful handling
 - [x] "Reliability"
 - [ ] TBD
 
 ## Concepts
 
 ### Session
 
 A "session" is a game session, requiring at least one Client.
 
 The game is defined as two instrument voices ("Trakcs") specifying one (or more?) of thirteen
 pitches to play on each of eight beats in an infinite loop. Each board consists of 
 exactly two instruments. Tracks must be requested and held by Clients in order to be 
 changed. One or more Tracks may be silent, depending on how many are held and updated.
 
 Clients view the session and manipulate its state ("config") through the web client.
 
 A session must have one Client. If the only Client in a session leaves, the
 session is destroyed by the server.
 
 ### Client
 
 A Client is a human user interacting with the server through a web client. The Client
 selects their board configuration through an interactive GUI, and receives sound 
 feedback derived from the board configuration.
 
 ### Board
 
 A board is the state of the game. It stores the configurations set by each user, to include
 which instrument each has chosen. It is essentially a 2x13x8 bitboard, where each value
 in the board indicates whether that note is "active" for the given beat. The Board also 
 includes information about how many beats per second have been selected for sound feedback.
 
 ### Track
 
 A Track is the config of a single instrument in the Session. A Client must request a Track
 successfully before they can change its config. If some Client holds a Track, they must 
 release the Track before another Client can successfully request it.
 
 ## Architecture
 
 ### Assumptions
 
 - The Client and Server config may be out of sync; the client will cache a local copy
 of the board config.
 
 ### Sockets Layer
 
 Client and Server exchange messages over websockets (one per unique Client: note that more 
 than one unique Client may exist on the same host machine, and that separate browswer tabs
 are considered to be unique Clients) according to the protocol specified in the RFC.
 
 Messages take the form of JSON objects.
 
 #### Example Control Messages & Notifications
 - (Client) Create new session
 - (Client) Join session
 - (Client) Leave session
 - (Server) Client left session
 - (Server) Client joined session
 
 #### Board Updates (Bidirectional)
 - Instrument type chosen
 - Beats per minute
 - 13 x 8 bitboard (13 notes x 8 beats)
 
 ### Server State: Sessions & Clients
 
 #### Home
 - A "menu session" every Client joins when they first connect
 - No Board in this session
 - Server state presented via Home: current available sessions
 
 #### Session
 - A Board (2x13x8 bitboard plus beats per second and possibly volume)
 - Two instrument Tracks
 - Each Session is defined by static state, updated asynchronously
 - Clients can join a Session and observe without owning a Track
 - Clients can control one or both Tracks in a Session
 
 #### Client
 - Connection info (IP, port)
 - ClientID (UUID String) and Nickname
 - Current sessions
 
 #### Administrator (Not Implemented)
 - Special Player class
 - Authentication-based
 - Can issue special commands to the server
    - Kick user
    - Delete session
 
 ### Server Actions
 
 The server's goal is to keep Clients synchronized by maintaining internal state according
 to the updates from Clients, and pushing those updates out to other Clients.
 
 ## Stretch Goals
 
 - AI player
 - Text chat in session
 - Player sets bpm
 - Per-session volume knob
 - Multiple instrument choices
 - Multiple Tracks per Session

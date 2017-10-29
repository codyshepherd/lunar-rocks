# Server Architecture
v1.1.1

## Requirements
### Functional
 - [ ] Accept Client Connections
 - [ ] Handle multiple clients
 - [ ] Client create session
 - [ ] Client list all sessions
 - [ ] Client join a session
 - [ ] Client leave a session
 - [ ] Client list members of a session
 - [ ] Client send messages to a session
 - [ ] Client join multiple sessions
 - [ ] Client send distinct messages to multiple selected sessions
 - [ ] Client disconnect
 - [ ] Server kick client
 - [ ] Handle client crashes
 
 ### Nonfunctional
 
 - [ ] Graceful handling
 - [ ] "Reliability"
 - [ ] TBD
 
 ## Concepts
 
 ### Session
 
 A "session" is a game session, requiring at least one player and no more than two.
 
 The game is defined as two instrument voices specifying one (or more?) of twelve
 pitches to play on each of eight beats in an infinite loop. Each board consists of 
 exactly two instruments. One instrument may be silent if only one player is present 
 in the session.
 
 Players view the session and manipulate its state ("config") through the web client.
 
 A session must have one player. If the only player in a session leaves, the
 session is destroyed by the server.
 
 ### Player
 
 A player is a human user interacting with the server through a web client. The player
 selects their board configuration through an interactive GUI, and receives sound 
 feedback derived from the board configuration.
 
 ### Board
 
 A board is the state of the game. It stores the configurations set by each user, to include
 which instrument each has chosen. It is essentially a 2x12x8 bitboard, where each value
 in the board indicates whether that note is "active" for the given beat. The Board also 
 includes information about how many beats per second have been selected for sound feedback.
 
 ## Architecture
 
 ### Assumptions
 
 - The Client and Server config may be out of sync; the client will cache a local copy
 of the board config.
 
 ### Sockets Layer
 
 Client and Server exchange messages over sockets (one per Player) according to a
 specified protocol.
 
 Messages take the form of JSON objects.
 
 #### Control Messages & Notifications
 - (Client) Create new session
 - (Client) Join session
 - (Client) Leave session
 - (Server) Player left session
 - (Server) Player joined session
 
 #### Board Updates (Bidirectional)
 - Instrument type chosen
 - Beats per minute
 - 12 x 8 bitboard (12 notes x 8 beats)
 
 ### Server State: Sessions & Players
 
 #### Home
 - A "menu session" every player joins when they first connect
 - No Board in this session
 - Server state presented via Home: current available sessions, current users
 
 #### Session
 - A Board (2x12x8 bitboard plus beats per second and possibly volume)
 - Two slots of Player information
 - Each session is managed by a separate thread
 
 #### Player
 - Connection info (IP, port)
 - Username
 - Current sessions
 
 #### Administrator
 - Special Player class
 - Authentication-based
 - Can issue special commands to the server
    - Kick user
    - Delete session
 
 ### Server Actions
 
 The server's goal is to update each player at least once every loop cycle (this figure 
 will be derived from the session's set BPM).
 
 ## Stretch Goals
 
 - AI player
 - Text chat in session
 - Player sets bpm
 - Per-session volume knob
 - Multiple instrument choices
 - One player manipulates multiple instruments

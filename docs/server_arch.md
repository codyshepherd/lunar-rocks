# Server Architecture
v1.0

## Requirements
### Functional
 - [ ] Accept Client Connections
 - [ ] Handle multiple clients
 - [ ] Client create room
 - [ ] Client list all rooms
 - [ ] Client join a room
 - [ ] Client leave a room
 - [ ] Client list members of a room
 - [ ] Client send messages to a room
 - [ ] Client join multiple rooms
 - [ ] Client send distinct messages to multiple selected rooms
 - [ ] Client disconnect
 - [ ] Server kick client
 - [ ] Handle client crashes
 
 ### Nonfunctional
 
 - [ ] Graceful handling
 - [ ] "Reliability"
 - [ ] TBD
 
 ## Concepts
 
 ### Room
 
 A "room" is a game session, requiring at least one player and no more than two.
 
 The game is defined as two instrument voices specifying one (or more?) of twelve
 pitches to play on each of eight beats in an infinite loop. Each board consists of 
 exactly two instruments. One instrument may be silent if only one player is present 
 in the Room.
 
 Players view the room and manipulate its state ("config") through the web client.
 
 A room must have one player. If the only player to a room leaves, the room is destroyed
 by the server.
 
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
 
 #### Two Socket Connections Per Client: Control & Content
 
 ##### Control: Sends control messages & notifications
 - (Client) Create new room
 - (Client) Join room
 - (Client) Leave room
 - (Server) Player left room
 - (Server) Player joined room
 
 ##### Content: Bitboard representing Client and Server configs
 - Header: Instrument type chosen
 - Header: Beats per minute
 - 12 x 8 bitboard (12 notes x 8 beats)
 
 ### Server State: Rooms & Players
 
 #### Idea: Lobby
 - A "menu room" every player joins when they first connect
 - No Board in this room
 - Server state presented via Lobby: current available rooms, current users
 
 #### Room
 - A Board (2x12x8 bitboard plus beats per second and possibly volume)
 - Two slots of Player information
 - Each room is managed by a separate thread
 
 #### Player
 - Connection info (IP, port)
 - Username
 - Current rooms
 
 #### Administrator
 - Special Player class
 - Authentication-based
 - Can issue special commands to the server
    - Kick user
    - Delete room
 
 ### Server Actions
 
 The server's goal is to update each player at least once every loop cycle (this figure 
 will be derived from the room's set BPM).
 
 ## Stretch Goals
 
 - AI player
 - Text chat in room
 - Player sets bpm
 - Per-room volume knob
 - Multiple instrument choices
 - One player manipulates multiple instruments
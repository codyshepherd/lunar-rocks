# Server Design & API Specification

## Custom Types

### RoomID
- typedef for Int

### Playername
- typedef for String

### Player
Member | Type | Notes
-------|------|------
name  | Playername | name of player
host  | IPAddress  | host location of player
port  | Int        | host port of player
rooms | [RoomId]   | list of rooms player currently in

### Board
Member | Type | Notes
-------|------|------
bitboard | [[[Bool]]] | A 3-D array of binary values
bpm      | Int        | Hardcoded to begin; stretch goal is making this user-settable

---

## Server API

### Object: MusicServer
CLI Arguments: 
- Port Number

Class Fields:

Member | Type | Notes
-------|------|------
player_map   | HashMap      | (Playername: [RoomId]) allows server to quickly store and retrieve player info
player_list  | [Playername] | A list of all connected players
room_map     | HashMap      | (RoomId: [Playername]) allows server to quickly retrieve players per room
room_list    | [RoomId]     | A list of all current rooms
a_room_threads | HashMap    | (RoomId: RoomThread) map of available rooms (rooms with one player)
a_room_list  | [RoomId]     | List of rooms currently available
room_threads | HashMap      | (RoomId: RoomThread) allows ServerThreads to hand off sockets to RoomThreads
admin        | String       | admin username
password     | SHA256 Hash  | hashed admin password

Singleton object that wraps primary server process.

#### main() : Unit
Function Arguments:
- None
Serves listening thread pools

### Class: ServerThread
Class Arguments:
- Socket: a socket on which a connection has been accepted

#### run() : Unit
Function Arguments: 
- None

Handles new connections, parses initial messages, and hands off socket to appropriate
RoomThread, creating new RoomThreads if necessary

### Class: RoomThread
Class Arguments:
- RoomId: Int

Class Fields:

Member | Type | Notes
-------|------|------
players        | [Playername] | A list of player names
num_players    | Int          | How many players are currently in the room
board          | Board        | A Scala class
clock          | Time         | A timer for sending updates to clients; derived from board.bpm
controlSockets | HashMap      | (Playername: Socket) Allows thread to communicate with Players
contentSockets | HashMap      | (Playername: Socket) Allows thread to communicate with Players
timeouts       | [Time]       | Timeout trackers in case sockets become unresponsive

#### run() : Unit
Function Arguments:
- None

Loops over player list, getting new messages from live connection buffers and updating
Room state according to player messages.

#### addPlayer(): Unit
Function Arguments:
- Playername: name of player to add
- control: socket for control messages
- content: socket for content messages

Add a player to Room

#### getNumPlayers(): Int
Function Arguments: 
- None

Returns current number of players in room.

#### removePlayer(): Unit

#### updatePlayers(): Unit

#### updateBoard(): Unit

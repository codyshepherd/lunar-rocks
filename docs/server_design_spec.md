## This file is outdated. Please refer to the RFC for current specification.

# Server Design & API Specification
version 0.1

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
romm     | RoomId     | Identifies to which room the board belongs
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

#### addPlayer() : Boolean

#### addRoom() : Boolean

#### removePlayer() : Boolean

#### removeRoom() : Boolean

#### kickPlayer() : Boolean

#### allRooms() : List[Room]

#### allPlayers() : List[Player]

### Class: ServerThread
Class Arguments:
- Socket: a socket on which a connection has been accepted

#### run() : Unit
Function Arguments: 
- None

Handles a single Client connection, parses incoming messages, calls appropriate functions in Room and Player.

### Class: Room
Description:

Must be synchronized or event-driven to handle two simultaneous server threads fiddling around in it. Akka looks like
a good candidate for event handling.

Class Arguments:
- id: Int
- firstPlayer: Player

Class Fields:

Member | Type | Notes
-------|------|------
players     | [Playername] | A list of player names
num_players | Int          | How many players are currently in the room
board       | Board        | A Scala class
clock       | Time         | A timer for sending updates to clients; derived from board.bpm
sockets     | HashMap      | (Playername: Socket) Allows thread to communicate with Players
timeouts    | [Time]       | Timeout trackers in case sockets become unresponsive

#### addPlayer(): Unit
Function Arguments:
- Playername: name of player to add
- socket: socket for control messages

Add a player to Room

#### getNumPlayers(): Int
Function Arguments: 
- None

Returns current number of players in room.

#### removePlayer(): Unit

#### getBoard(): Unit

#### postBoard(): Unit

## Message Types

ID | Description | Initiated By | Includes | Notes
---|-------------|--------------|----------|------
100 | Update Board        | Either | Board                 | Bi-directional
101 | Create Room         | Client |                       | Includes add player to room
102 | Room Created        | Server | RoomId                |
103 | Join Room           | Client | RoomId                | 
104 | Leave Room          | Client | RoomId                | 
105 | Request All Players | Client |                       |
106 | All Players         | Server | [Players]             |
107 | Request All Rooms   | Client |                       |
108 | All Rooms           | Server | [(RoomId: [Players])] |
109 | Client Kick         | Server |                       |
110 | Client Disconnect   | Client | [RoomId]              |

## Message Format
See JSON schema 'src/schema/msg_header.json'

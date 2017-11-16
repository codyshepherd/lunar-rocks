# Music Application RFC Specificaiton

A collaborative music webApp by _Brian Ginsburg_ and _Cody Shepherd_

## 1. Intro & Concepts

### 1.1 Client

A client is any web browser connecting to a server. A client sends messages
to a server and receives messages from a server. Each client is uniquely
identified by a UUID (rfc 4122). In addition, the server must know the username of the
client and the host the client is running on. For each browser tab or
window, a client may display the home page or a session.

The home page is a listing of available sessions and provides the client
with an option to add sessions. When a client requests a new session, the
server fulfills the request by sending an integer SessionID. A client tracks
all sessions they have joined or added.

A session is a page that displays a musical interface (a "board") that the
client interacts with to make music. Any number of clients may view a
session, but at most *p* clients may be making music, where *p* is some
number of sub-interfaces ("tracks"). A session will display all clients
currently viewing a session, and the current tempo in beats per minute
expressed as a floating point number. In addition, a session will display
session IDs for any other sessions the client currently has open in another
browser tab or window.

A board consists of *p* tracks, each representing a separate instrument.
Each track is a a grid with *n* columns and *m* rows, where columns
represent time events ("beats") and rows represent sounds (e.g. an
instrument played at some pitch or a drum hit.). Taken together, rows and
columns form a grid of rests and note events.

A rest or note event may have any duration from 1 to *n*. A rest is encoded
in the grid with a sequence of 0's with a length equal to the length of the
rest. A note event is encoded in the grid with a sequence of integers from 1
to the duration of the note event.

A simple track might look like the following:
```
    ----------
A: |00000000|
B: |10101010|
C: |12340000|
D: |12345678|
    ----------
```

In this track, sound D is played for a duration of 8 starting on the first
beat. Sound C is played for a duration of 4 starting on the first beat, and
is silent for the last four beats. Sound B is played for a duration of 1 on
alternating beats and rests between each note event. Sound A is never played.

### 1.2 Server

The Server is the program component that stores a version of all Sessions, and
handles asynchronous updates to, and requests for, Session state from Clients.

The Server sends and receives updates and other messages to and from Clients
via websockets, either when the Clients request updates, or when a Client's 
Session is updated by another Client in the same Session.

The Server handles asynchronous messages using a Select-style methodology for
handling I/O in a non-blocking manner.

The Server tracks bookeeping information necessary for the proper functioning of
the application, to include: 
- connected Clients, identified by UUID and nickname
- active Sessions per Client, organized by ClientID 
- active Sessions (copyless redundant storage), organized by SessionID
- maximum possible Sessions per Client, identified by a constant value

The Server handles Client crashes by relying on the websocket layer to raise an
exception if a websocket is timed out or otherwise broken.

## 2. Messages

Clients and servers send each other messages. A client should expect a
response from the server, which may be an explicit or implicit
acknowledgment depending on the message type. Message types are described in
section 4.

Each message must contain the following parts: an integer source identifier
that indicates a client or server, an integer message identifier that
indicates message type, and a message payload. All messages must conform to
the JSON data interchange format (rfc 7159).

Messages take the general form shown below.
    
```
{
    "sourceID": integer,
    "messageID": integer,
    "payload": {...}
}
```

The payload varies by the message type, and may include any of the
following: an integer session identifier, an integer track identifier, or a
session object. Section 4 describes payloads for each message type.
    
A session object must contain the following parts: a session identifier, an
array client identifiers, a floating point tempo, and a board array. A board
array contains *p* track objects, where *p* is left to the implementor. A
track object contains an integer track identifier, an integer client
identifier, and an array of arrays that represents the grid of rests and
note events described in section 1.1.

A session object takes the following form.

```
{
        "sessionID": integer,
        "clients": [UUID],
        "tempo": integer,
        "board": [trackObject]
}
```

A track object takes the following form.
```
{
        "trackID": integer,
        "clientID": UUID,
        "grid":  [[integer]]
}
```
    
    
## 3. Communication Flow

All communication is between a client and a server, and communications use
either HTTP or Websockets. The initial contact from a client to a server is
done over HTTP when the client visits a website hosting an application that
implements the protocol. The client is sent an `index.html` file with a
JavaScript call to open a Websocket. The client requests a Websocket from
the server with an "upgrade" message, and the server replies with a
"switching protocols" message. From this point forward, all communication is
carried out over the Websocket.

Communication in the protocol is one-to-all and one-to-many. 

### 3.1 One-to-all (broadcast)

One-to-all communication occurs only on the home page where the listing of
sessions is available to all connected clients. When a client requests a new
session, all clients are notified that a new session has been added.

### 3.2 One-to-many

One-to-many communcation occurs in sessions when a client requests a track,
relinquishes a track, updates a track, or changes the tempo. All clients
currently viewing the session are notified of the resulting change. Note
that for the message sender, this notification serves as an implicit
acknowledgement of their message.

A special form of one-to-many communication occurs when a client wishes to
update multiple sessions with the configuration of their current session.
This communication will result in updates to sessions the client has open
but is not viewing.

### 3.3 Connection Failures

To ensure an active connection, communication must regularly occur between
the client and server. This may take the form of keep-alive messages for
example.

If a client has not received a message from a server in over ten seconds, it
should assume the connection has been lost and notify the user. When the
connection has been re-established, the client should send an update to the
server with changes it has made since the last successful communication.

If a server has not received a message from a client in over ten seconds, it
should hold information about the client for another twenty seconds and
await a new Websocket connection. If a new connection is made, the client
will send its sourceID in its first message and the server will restore the
lost session. If a new connection is not made, the server will consider the
connection with client terminated.

## 4. Message Details
As detailed in Section 2, Messages are identified by their message ID. 

Message IDs and descriptions are detailed in the following table:

| ID | Description | Initiated By | Payload | Notes |
|----|-------------|----------|---------|-------------------------------------|
| 100| Update Session     | Either | Session                | Used whenever Session states need to be updated |
| 101| Create Session     | Client | | This request indicates to the Server that the Client wants to start a new Session |
| 102| Session Created    | Server | Session                | The Server responds to a 101 request with the newly-created Session |
| 103| Join Session       | Client | SessionID              | Used whenever a Client wants to join an existing Session |
| 104| Leave Session      | Client | SessionID              | Used whenever a Client wants to leave a Session; if Client is last to leave, Session is destroyed |
| 105| Update SessionList | Server | [SessionID]            | Server sends this update to Clients when its active Server list is updated |
| 106| Disconnect         | Client | | Client notifies Server it is disconnecting |
| 107| Disconnect         | Server | | Server notifies Client that either the Server is going down, or Client is being kicked |
| 108| Broadcast          | Client | (Track, [SessionID]) | Used when the Client wants to update a set of active Sessions with a selected track |
| 109| Request Track      | Client | (SessionID, TrackID)   | Used when a Client wants to select a Track in a Session |
| 110| Relinquish Track   | Client | (SessionID, TrackID)   | Used when a Client wants to relinquish a Track in a Session
| 111| Track Request Response | Server | Boolean | Server notifies Client as to the status of its Track Request |
| 112| Client Connect     | Client | Nickname (string) | The Client sends this message when first connecting with the server over websocket |
| 113| Client Connected   | Server | ClientID | The Server responds to msgID: 112 with the Client's ClientID |
| 114| Error              | Either | Error Description (string) | This message is for general debugging |

### Payload Object Key-Value Pairs

Every payload is some kind of `{}` object, even if it is empy. Following are the descriptions of what key, value pairs belong in the payload object for a given messageID.
Wherever two keys/values are listed, they should be interpreted respectively. E.g. keys 'a', 'b' and values c, d indicate a payload object that looks like:
```
{
    'a':c,
    'b':d
}
```

| messageID | Payload | Key | Value |
|-----|---------|-----|-------|
| 100 | Session | 'session' | session object |
| 101 | None (`{}`) | | |
| 102 | SessionID | 'session' | session object |
| 103 | SessionID | 'sessionID' | Int |
| 104 | SessionID | 'sessionID' | Int |
| 105 | [SessionID] | 'sessionIDs' | [Int] |
| 106 | None | | |
| 107 | None | | |
| 108 | (Track, [SessionID]) | 'track', 'sessionIDs' | track object, [Int]  |
| 109 | (SessionID, TrackID) | 'sessionID', 'trackID' | Int, Int |
| 110 | (SessionID, TrackID) | 'sessionID', 'trackID' | Int, Int |
| 111 | Boolean {True, False} | 'status' | Boolean {True, False} |
| 112 | String | 'nickname' | String |
| 113 | ClientID (UUID String) | 'clientID' | String |
| 114 | String | 'error' | String |


Music Application RFC Specificaiton
    Brian Ginsburg
    Cody Shepherd

1. Intro & Concepts

    1.1 Client

    A client is any web browser connecting to the server. Each client is
    uniquely identified by a UUID. In addition, the server must know the
    username of the client and the host the client is running on.
    
    For each browser tab or window, a client may display the home page or a
    session. The home page is a listing of available sessions and provides the
    client with an option to add sessions.
    
    A session is a page that displays a musical interface (a "board") that the
    client interacts with to make music. Any number of clients may view a
    session, but two clients at most may be making music. A session will display
    all clients currently viewing a session. In addition, a session will display
    session IDs for any other sessions the client currently has open in another
    browser tab or window.
    
    A board consists of two tracks, each representing a separate instrument.
    Each track is a a grid with *n* columns and *m* rows, where columns
    represent time events ("beats") and rows represent sounds (e.g. an
    instrument at some pitch or a drum hit.). Taken together, rows and columns
    form a grid of rests and note events.
    
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
    

    1.2 Server

2. Messages

3. Communication Flow

4. Message Details

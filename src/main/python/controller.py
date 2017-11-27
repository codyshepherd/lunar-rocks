import numpy as np
import random
import uuid
import logging

DEFAULT_TONES = 13
DEFAULT_BEATS = 8
MAX_SESS_ID = 1000
MIN_SESS_ID = 1
DEFAULT_TEMPO = 8
LOG_NAME = "server.log"
TRACK_IDS = list(range(2))

LOGGER = logging.getLogger(LOG_NAME)
logging.basicConfig(filename=LOG_NAME,level=logging.DEBUG)

class Track:

    def __init__(self, trackID, dimensions=(DEFAULT_TONES, DEFAULT_BEATS), tempo=DEFAULT_TEMPO):
        LOGGER.debug("Track " + str(trackID) + " created")
        self.trackID = trackID              # String
        self.clientID = ''                  # UUID String
        self.clientNick = ''                # String
        self.grid = np.zeros(dimensions, dtype=int).tolist() # 2D list of ints
        self.dimensions = dimensions        # tuple of ints

    def update(self, trk):
        """
        update self from trk dict

        :param trk: dict in same format as output of export()
        :return: boolean about success of funciton
        """
        LOGGER.debug("Track.update() started")
        newgrid = trk.get('grid')
        if not newgrid:
            LOGGER.error("No new grid state provided to Track.update()")
            return False

        if not self.check_dimensions(newgrid):
            LOGGER.error("New grid has wrong dimensions in Track.update()")
            return False

        self.grid = newgrid 
        return True

    def check_dimensions(self, grd):
        """
        Ensures dimensions of given state matches those of self.dimensions

        :param grd: a 2-D list
        :return: boolean about success of function
        """
        LOGGER.debug("Task.check_dimensions() started")
        rows = len(grd)
        cols = len(grd[0])

        if not (rows==self.dimensions[0] and cols==self.dimensions[1]):
            LOGGER.error("grid passed to Task.check_dimensions is the wrong dimensions!")
            return False

        return True

    def export(self):
        """
        exports internal parametrs as json-serializable dict

        :return: well-formed dict according to the RFC
        """
        LOGGER.debug("Task.export() started")
        return {
            "trackID": self.trackID,
            "clientID": self.clientID,
            "nickname": self.clientNick,
            "grid": self.grid
        }

class Session:

    def __init__(self, sessionID):
        LOGGER.debug("Session " + str(sessionID) + " created")
        self.clientlist = []            # list of (UUID, nickname) pairs
        self.sessionID = sessionID
        self.trackIDs = TRACK_IDS
        self.tracks = {}
        for num in self.trackIDs:
            self.tracks[num] = Track(num)

    def update(self, sess):
        """
        update self from sess dict

        :param sess: a dict in same format as output of Session.export()
        :return: output of self.export
        """
        LOGGER.debug("Session.update() started")
        trackslist = sess.get('tracks')
        if not trackslist:
            LOGGER.error("No tracklist provided to Session.update() by sess argument")
            return None

        for (new, trackobj) in zip(trackslist, self.tracks):
            if not trackobj.update(new):
                LOGGER.error("Session.update() quitting because of error in Track.update()")
                return None

        return self

    def update_track(self, cid, trk):
        """
        Updates the specified track if the client owns it

        :param cid: clientID
        :param trk: track dict (same as output of Track.export())
        :return: boolean about success of function
        """
        LOGGER.debug("Session.update_track() started")

        tid = trk['trackID']

        track = self.tracks.get(tid)

        if not track:
            LOGGER.error("No track by id " + str(tid) + " found")
            return False

        if track.clientID != cid:
            LOGGER.error("Client " + str(cid) + " doesn't own track " + str(tid))
            return False

        if not track.update(trk):
            LOGGER.error("Track update failed")
            return False

        return True

    def request_track(self, cid, nick, tid):
        """
        Adds cid as owner to specified track if that track is available

        :param cid: clientID string
        :param nick: client nickname string
        :param tid: trackID string
        :return: trackID, sessionID, boolean - the first two fields are None if last is False
        """
        LOGGER.debug("Session.request_track() started")

        if cid not in [x[0] for x in self.clientlist]:
            LOGGER.error("clientID passed to Session.request_track() not in session clientlist")
            return (None, None, False)

        if tid not in self.trackIDs:
            LOGGER.error("trackID passed to Session.request_track() not in trackIDs")
            return (None, None, False)

        t = self.tracks.get(tid)

        if not t:
            LOGGER.error("For some reason the trackID passed to Session.request_track() can't find a track!")
            return (None, None, False)

        if t.clientID:
            LOGGER.error("Track specified to Session.request_track() is already owned")
            return (None, None, False)

        t.clientID = cid
        t.clientNick = nick
        LOGGER.debug("Session.request_track() returning " + str(t.trackID) + ", " + str(self.sessionID) + ", " + str(True))
        return (t.trackID, self.sessionID, True)

    def relinquish_track(self, cid, tid):
        """
        Removes client as owner of specified track

        :param cid: clientID string
        :param tid: trackID string
        :return: boolean - whether function was successful or not
        """
        LOGGER.debug("Session.relinquish_track() started")

        if cid not in [x[0] for x in self.clientlist]:
            LOGGER.error("clientID passed to Session.relinquish_track() not in session's clientlist")
            return False

        if tid not in self.trackIDs:
            LOGGER.error("trackID " + str(tid) + " provided to Session.relinquish_track() not in Session's trackIDs")
            return False

        t = self.tracks.get(tid)

        if not t:
            LOGGER.error("For some reason the trackID " + str(tid) + " passed to Session.relinquish_track() can't find a track!")
            return False

        t.clientID = ''
        t.clientNick = ''
        return True

    def add_client(self, cid, nick):
        """
        Adds client to specified track

        :param cid: clientID string
        :param nick: client nickname string
        :return: boolean - whether function was successful or not

        """
        LOGGER.debug("Session.add_client() started")

        if cid not in [x[0] for x in self.clientlist]:
            self.clientlist.append((cid, nick))

        return True

    def remove_client(self, cid):
        """
        Removes specified client from Session, including removing them from any tracks they are part of.

        :param cid: clientID string
        :return: boolean - whether the function was successful or not
        """
        LOGGER.debug("Session.remove_client() started")

        if cid not in [x[0] for x in self.clientlist]:
            LOGGER.error("id provided to Session.remove_client() is not a member of the session")
            return False

        #self.clientlist = filter(lambda x: x != cid, self.clientlist)
        self.clientlist = [x for x in self.clientlist if x[0] != cid]

        for tid in self.trackIDs:
            self.relinquish_track(cid, tid)

        return True

    def is_empty(self):
        """
        States whether the Session has no current clients
        True if no clients, false otherwise.

        :return: boolean - whether function was successful or not
        """
        LOGGER.debug("Session.is_empty() started")
        if not self.clientlist:
            return True

        return False

    def export(self):
        """
        Exports pertinent contents as a json-serializable dict

        :return: session as dict according to RFC
        """
        LOGGER.debug("Session.export() started")
        return {
            "clients": [x[1] for x in self.clientlist],  # export only client nicknames
            "sessionID": self.sessionID,
            "tempo": DEFAULT_TEMPO,
            "board": [x.export() for x in self.tracks.values()]
        }

class Controller:

    def __init__(self):
        LOGGER.debug("Controller.__init__() started")
        self.clients = {}           # (UUID: String)
        self.client_sessions = {}   # (UUID: List(SessionID))
        self.sessions = {}          # (SessionID: Session)
        self.sockets = {}           # UUID: websocket
        self.addrs = {}             # host: clientID, port

    def log_cid_by_address(self, cid, addr):
        """
        Tracks clientIDs and port numbers by host address,
        to assist in handling of Duplicate 112 messages from
        the same client.

        :param cid: clientID
        :param addr: (host, port) tuple
        :return: None
        """
        LOGGER.debug("Controller.log_cid_by_address() started")

        self.addrs[str(addr)] = cid

    def get_cid_by_address(self, addr):
        """
        Allows for retrieval of (host,port) address by clientID

        :param addr: a host,port tuple
        :return: clientID or None
        """

        return self.addrs.get(str(addr))

    def log_socket(self, cid, sock):
        """
        Tracks websocket connections by client ID
        :param cid:  UUID string for the client
        :param sock: a websocket object
        :return: None
        """

        self.sockets[cid] = sock

    def get_socket(self, cid):
        """
        Returns the websocket by clientID
        :param cid: UUID string for client
        :return: websocket
        """
        return self.sockets.get(cid)

    def get_session(self, sid):
        """
        returns the IDed session as a dict

        :param sid: sessionID int
        :return: output of Session.export()
        """
        LOGGER.debug("Controller.get_session() started")
        sess = self.sessions.get(sid)

        if not sess:
            LOGGER.error("No session found by the sessionID passed to Controller.get_session()")
            return None

        return sess.export()

    def new_session(self):
        """
        Start a new session

        :return: sessionID (int) of new session
        """
        LOGGER.debug("Controller.new_session() started")
        sid = MIN_SESS_ID
        while sid in self.sessions.keys():
            sid = random.randint(MIN_SESS_ID, MAX_SESS_ID)
        
        self.sessions[sid] = Session(sid)
        return sid

    def new_client(self, nick):
        """
        Client joins server

        :param nick: String specifying client nickname (human readable name)
        :return: uuid string for new client
        """
        LOGGER.debug("Controller.new_client() started")
        cid = uuid.uuid4()
        while cid in self.clients.keys():
            cid = uuid.uuid4()

        self.clients[str(cid)] = nick
        return str(cid)

    def client_exit(self, cid):
        """
        Client exits/disconnects from server

        :param cid: clientID string
        :return: Boolean - whether or not function succeeded
        """
        LOGGER.debug("Controller.client_exit() started")

        if cid not in self.clients.keys():
            LOGGER.error("cid provided to Controller.client_exit() not in clients.keys()")
            return False

        c_sessions = self.client_sessions[cid]
        for session in c_sessions:
            session.remove_client(cid)
            if session.is_empty():
                del self.sessions[session.sessionID]

        self.client_sessions[cid] = []
        del self.clients[cid]
        del self.sockets[cid]
        return True

    def client_join(self, cid, sid):
        """
        Adds client to a session

        :param cid: clientID
        :param sid: sessionID
        :return: Boolean about success of funciton
        """
        sess = self.sessions.get(sid)
        if not sess:
            return False

        nick = self.clients.get(cid)
        if not nick:
            return False

        sess.add_client(cid, nick)
        if not self.client_sessions.get(cid):
            self.client_sessions[cid] = []
        self.client_sessions[cid].append(sess.sessionID)
        return True

    def client_leave(self, cid, sid):
        """
        Client leaves a Session

        :param cid: clientID
        :param sid: sessionID
        :return: Boolean about success of function
        """
        sess = self.sessions.get(sid)
        if not sess:
            return False

        if not self.clients.get(cid):
            return False

        if not sess.remove_client(cid):
            return False

        c_sessions = self.client_sessions[cid]
        #self.client_sessions[cid] = filter(lambda x: x != sid, c_sessions)
        self.client_sessions[cid] = [x for x in c_sessions if x != sid]

        if sess.is_empty():
            del self.sessions[sid]

        return True

    def update_session(self, cid, sess):
        """
        POST-style update from client

        :param cid: string - clientID
        :param sess: dict - session represented as dict, same as output of Session.export()
        :return: json-serializable object (None if update failed)
        """
        LOGGER.debug("update_session() started")
        sid = sess.get('sessionID')

        if not sid:
            LOGGER.error("No session ID provided in argument!")
            return None

        sessionIDs = self.client_sessions.get(cid)
        if not sessionIDs or sid not in sessionIDs:
            LOGGER.error("Wanted to update a session it didn't own.")
            return None

        session = self.sessions.get(sid)
        if not session:
            LOGGER.error("Session not found")
            return None

        return session.update(sess)

    def request_track(self, cid, sid, tid):
        """
        Allows a client to request ownership of track

        :param cid: id of client requesting track
        :param sid: sessionID of track
        :param tid: trackID
        :return: trackID, sessionID, Boolean
        """
        LOGGER.debug("Controller.request_track() started")

        sess = self.sessions.get(sid)

        if not sess:
            LOGGER.error("sid provided does not exist")
            return None, None, False

        nick = self.clients.get(cid)
        if not nick:
            LOGGER.error("cid provided does not exist")
            return None, None, False

        return sess.request_track(cid, nick, tid)

    def relinquish_track(self, cid, sid, tid):
        """
        Allows client to relinquish ownership of a track they own

        :param cid: clientID string
        :param sid: sessionID
        :param tid: trackID
        :return: boolean about success of function (True)
        """
        LOGGER.debug("Controller.relinquish_track() started")

        sess = self.sessions.get(sid)

        if not sess:
            LOGGER.error("sid provided does not exist")
            return False

        return sess.relinquish_track(cid, tid)

    def broadcast(self, cid, sids, trk):
        """
        Allows client to broadcast a track to all owned sessions/tracks

        :param cid: clientID
        :param sids: list of sessionIDs
        :param trk: a track dict (same as output of Track.export())
        :return: list of sessions
        """
        LOGGER.debug("Controller.broadcast() started")

        tid = trk.get("trackID")
        if not tid:
            LOGGER.error("No trackID given")
            return None

        client_sessions = self.client_sessions.get(cid)
        sessions = []

        for id in sids:
            if id not in client_sessions:
                LOGGER.error("Client " + str(cid) + " not in session " + str(id))
                continue

            sess = self.sessions.get(id)

            if not sess:
                LOGGER.error("No session found for sessionID " + str(id))
                continue

            if not sess.update_track(cid, trk):
                LOGGER.error("Update track failed for client " + str(cid) + " session " + str(id) + " track " + str(tid))
                continue

            sessions.append(sess)

        return sessions
















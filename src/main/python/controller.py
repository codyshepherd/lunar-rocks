import numpy as np
import random
import uuid
import logging
import os

DEFAULT_TONES = 13
DEFAULT_BEATS = 8
MAX_CLIENTS = 1000
DEFAULT_TEMPO = 8
LOG_NAME = "server.log"

#if os.path.isfile(LOG_NAME):
#   os.remove(LOG_NAME)


LOGGER = logging.getLogger(LOG_NAME)
logging.basicConfig(filename=LOG_NAME,level=logging.DEBUG)

class Track:

    def __init__(self, trackID, dimensions=(DEFAULT_TONES, DEFAULT_BEATS), tempo=DEFAULT_TEMPO):
        self.trackID = trackID              # String
        self.clientID = ""                  # UUID
        self.grid = np.zeros(dimensions, dtype=int).tolist() # 2D list of ints
        self.dimensions = dimensions        # tuple of ints

    def update(self, trk):
        """
        update self from trk dict

        :param trk: dict in same format as output of export()
        """
        LOGGER.debug("update() started")
        newgrid = trk.get('grid')
        if not newgrid:
            LOGGER.error("No new grid state provided to Track.update()")
            return False

        if not self.check_dimensions(newgrid):
            LOGGER.error("New grid has wrong dimensions")
            return False

        self.grid = newgrid 
        return True

    def check_dimensions(self, grd):
        """
        Ensures dimensions of given state matches those of self.dimensions

        :param grd: a 2-D list
        """
        rows = len(grd)
        cols = len(grd[0])

        if not (rows==self.dimensions[0] and cols==self.dimensions[1]):
            return False

        return True

    def export(self):
        """
        exports internal parametrs as json-serializable dict
        """
        return {
            "trackID": self.trackID,
            "clientID": self.clientID,
            "grid": self.grid
        }

class Session:

    def __init__(self, sessionID):
        self.clientlist = []
        self.sessionID = sessionID
        self.tracks = [Track(str(sessionID) + 'a'), Track(str(sessionID) + 'b')]

    def update(self, sess):
        """
        update self from sess dict

        :param sess: a dict in same format as output of Session.export()
        """
        LOGGER.debug("update() started")
        trackslist = sess.get('tracks')
        if not trackslist:
            LOGGER.error("No tracklist provided by sess argument")
            return False

        for (new, trackobj) in zip(trackslist, self.tracks):
            if not trackobj.update(new):
                return False

        return True
            

    def add_client(self, id):
        if id in self.clientlist:
            return False
        self.clientlist.append(id)

        for track in self.tracks:
            if track.clientID == "":
                track.clientID = id
                break

        return True

    def remove_client(self, id):
        if id not in self.clientlist:
            return False

        self.clientlist = filter(lambda x: x != id, self.clientlist)
        for track in self.tracks:
            if track.clientID == id:
                track.clientID = ""
                #TODO: let the next "waiting" client into this track
        return True

    def is_empty(self):
        if not self.clientlist:
            return True

        return False

    def export(self):
        return {
            "clientlist", self.clientlist,
            "sessionID", self.sessionID,
            "tracks", [x.export for x in self.tracks]
        }

class Controller:

    def __init__(self):
        self.clients = {} #(UUID: String)
        self.client_sessions = {} #(UUID: List(SessionID))
        self.sessions = {} #(SessionID: Session)

    def get_session(self, sid):
        """
        returns the IDed session as a dict
        """
        sess = self.sessions.get(sid)
        if not sess:
            return None

        return sess.export()

    def new_session(self):
        """
        Start a new session

        returns id of new session
        """
        id = 0
        while id in self.sessions.keys():
            id = random.randint(0, MAX_CLIENTS)
        
        self.sessions[id] = Session(id)
        return id

    def new_client(self, nick):
        """
        Client joins server

        returns uuid for new client
        """
        cid = uuid.uuid4()
        while cid in self.clients.keys():
            cid = uuid.uuid4()

        self.clients[str(cid)] = nick
        return str(cid)

    def client_exit(self, cid):
        """
        Client exits/disconnects from server
        """
        if cid not in self.clients.keys():
            return False

        c_sessions = self.client_sessions[cid]
        for session in c_sessions:
            session.remove_client(cid)
            if session.is_empty():
                del self.sessions[session.sessionID]

        self.client_sessions[cid] = []
        del self.clients[cid]
        return True

    def client_join(self, cid, sid):
        """
        Client joins a Session
        """
        sess = self.sessions.get(sid)
        if not sess:
            return False

        client = self.clients.get(cid)
        if not client:
            return False

        sess.add_client(cid)
        self.client_sessions[cid].append(sess.sessionID)
        return True

    def client_leave(self, cid, sid):
        """
        Client leaves a Session
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
        """
        LOGGER.debug("update_session() started")
        sid = sess.get('sessionID')

        if not sid:
            LOGGER.error("No session ID provided in argument!")
            return False

        sessionIDs = self.client_sessions.get(cid)
        if not sessionIDs or sid not in sessionIDs:
            LOGGER.error("Wanted to update a session it didn't own.")
            return False

        session = self.sessions.get(sid)
        if not session:
            LOGGER.error("Session not found")
            return False

        if not session.update(sess):
            return False
        else:
            return True
        






















import numpy as np
import random
import uuid

DEFAULT_TONES = 13
DEFAULT_BEATS = 8
MAX_CLIENTS = 1000
DEFAULT_TEMPO = 8

class Track:

    def __init__(self, trackID, dimensions=(DEFAULT_TONES, DEFAULT_BEATS), tempo=DEFAULT_TEMPO):
        self.trackID = trackID
        self.client = ""    #UUID
        self.grid = np.zeros(dimensions)

    def export(self):
        return {
            "trackID": self.trackID,
            "clientID": self.client,
            "grid": self.grid
        }

class Session:

    def __init__(self, sessionID):
        self.clientlist = []
        self.sessionID = sessionID
        self.tracks = [Track(), Track()]

    def add_client(self, id):
        if id in self.clientlist:
            return False
        self.clientlist.append(id)

        for track in self.tracks:
            if track.client == "":
                track.client = id
                break

        return True

    def remove_client(self, id):
        if id not in self.clientlist:
            return False

        self.clientlist = filter(lambda x: x != id, self.clientlist)
        for track in self.tracks:
            if track.client == id:
                track.client = ""
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
        self.client_sessions = {} #(UUID: List(Session))
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
            id = random.randint(MAX_CLIENTS)
        
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
        self.client_sessions[cid].append(sess)
        return true

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
        self.client_sessions[cid] = filter(lambda x: x.sessionID != sid, c_sessions)

        if sess.is_empty():
            del self.sessions[sid]
























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
TRACK_IDS = list(range(2))

#if os.path.isfile(LOG_NAME):
#   os.remove(LOG_NAME)


LOGGER = logging.getLogger(LOG_NAME)
logging.basicConfig(filename=LOG_NAME,level=logging.DEBUG)

class Track:

    def __init__(self, trackID, dimensions=(DEFAULT_TONES, DEFAULT_BEATS), tempo=DEFAULT_TEMPO):
        LOGGER.debug("Track " + str(trackID) + " created")
        self.trackID = trackID              # String
        self.clientID = ""                  # UUID
        self.grid = np.zeros(dimensions, dtype=int).tolist() # 2D list of ints
        self.dimensions = dimensions        # tuple of ints

    def update(self, trk):
        """
        update self from trk dict

        :param trk: dict in same format as output of export()
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
        """
        LOGGER.debug("Task.export() started")
        return {
            "trackID": self.trackID,
            "clientID": self.clientID,
            "grid": self.grid
        }

class Session:

    def __init__(self, sessionID):
        LOGGER.debug("Session " + str(sessionID) + " created")
        self.clientlist = []
        self.sessionID = sessionID
        self.trackIDs = TRACK_IDS
        self.tracks = {}
        for num in self.trackIDs:
            self.tracks[num] = Track(str(num))

    def update(self, sess):
        """
        update self from sess dict

        :param sess: a dict in same format as output of Session.export()
        :returns: boolean about the success of the function
        """
        LOGGER.debug("Session.update() started")
        trackslist = sess.get('tracks')
        if not trackslist:
            LOGGER.error("No tracklist provided to Session.update() by sess argument")
            return False

        for (new, trackobj) in zip(trackslist, self.tracks):
            if not trackobj.update(new):
                LOGGER.error("Session.update() quitting because of error in Track.update()")
                return False

        return True
            
    def request_track(self, cid, tid):
        """
        Adds cid as owner to specified track if that track is available

        :param cid: clientID string
        :param tid: trackID string
        :returns: boolean - whether client was added successfully or not
        """
        LOGGER.debug("Session.request_track() started")

        if tid not in self.trackIDs:
            LOGGER.error("trackID passed to Session.request_track() not in trackIDs")
            return False

        t = self.tracks.get(str(tid))

        if not t:
            LOGGER.error("For some reason the trackID passed to Session.request_track() can't find a track!")
            return False

        if t.clientID != '':
            LOGGER.error("Track specified to Session.request_track() is already owned")
            return False

        t.clientID = cid
        return True

    def relinquish_track(self, cid, tid):
        """
        Removes client as owner of specified track

        :param cid: clientID string
        :param tid: trackID string
        :returns: boolean - whether function was successful or not
        """
        LOGGER.debug("Session.relinquish_track() started")

        if tid not in self.trackIDs:
            LOGGER.error("trackID " + str(tid) + " provided to Session.relinquish_track() not in Session's trackIDs")
            return False

        t = self.tracks.get(str(tid))

        if not t:
            LOGGER.error("For some reason the trackID " + str(tid) + " passed to Session.relinquish_track() can't find a track!")
            return False

        t.clientID = ''
        return True

    def add_client(self, cid):
        """
        Adds client to specified track

        :param cid: clientID string
        :returns: boolean - whether function was successful or not
        """
        LOGGER.debug("Session.add_client() started")

        if cid not in self.clientlist:
            self.clientlist.append(cid)

        return True

    def remove_client(self, cid):
        """
        Removes specified client from Session, including removing them from any tracks they are part of.

        :param cid: clientID string
        :returns: boolean - whether the function was successful or not
        """
        LOGGER.debug("Session.remove_client() started")

        if cid not in self.clientlist:
            LOGGER.error("id provided to Session.remove_client() is not a member of the session")
            return False

        #self.clientlist = filter(lambda x: x != cid, self.clientlist)
        self.clientlist = [x for x in self.clientlist if x != cid]

        for tid in self.trackIDs:
            self.relinquish_track(cid, tid)     #TODO: let the next "waiting" client into this track

        return True

    def is_empty(self):
        """
        States whether the Session has no current clients
        True if no clients, false otherwise.

        :returns: boolean - whether function was successful or not
        """
        LOGGER.debug("Session.is_empty() started")
        if not self.clientlist:
            return True

        return False

    def export(self):
        """
        Exports pertinent contents as a json-serializable dict

        :returns: session as dict according to RFC
        """
        LOGGER.debug("Session.export() started")
        return {
            "clientlist", self.clientlist,
            "sessionID", self.sessionID,
            "tracks", [x.export for x in self.tracks]
        }

class Controller:

    def __init__(self):
        LOGGER.debug("Controller.__init__() started")
        self.clients = {} #(UUID: String)
        self.client_sessions = {} #(UUID: List(SessionID))
        self.sessions = {} #(SessionID: Session)

    def get_session(self, sid):
        """
        returns the IDed session as a dict

        :param sid: sessionID int
        :returns: output of Session.export()
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

        :returns: sessionID (int) of new session
        """
        LOGGER.debug("Controller.new_session() started")
        sid = 0
        while sid in self.sessions.keys():
            sid = random.randint(0, MAX_CLIENTS)
        
        self.sessions[sid] = Session(sid)
        return sid

    def new_client(self, nick):
        """
        Client joins server

        :param nick: String specifying client nickname (human readable name)
        :returns: uuid string for new client
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
        :returns: Boolean - whether or not function succeeded
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
        return True

    def client_join(self, cid, sid):
        """
        Adds client to a session
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
        






















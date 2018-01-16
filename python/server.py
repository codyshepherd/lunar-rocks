"""
Lunar Rocks Websocket Server

This module handles websocket traffic to and from the server.

Python >= 3.5 required.
"""

import asyncio
import websockets
from websockets.exceptions import ConnectionClosed
import json
import controller
import logging
from logging.handlers import RotatingFileHandler
import uuid
import argparse

__author__ = "Cody Shepherd & Brian Ginsburg"
__copyright__ = "Copyright 2017, Cody Shepherd & Brian Ginsburg"
__credits__ = ["Cody Shepherd", "Brian Ginsburg"]
#__license__ =
__version__ = "1.0"
__maintainer__ = "Cody Shepherd"
__email__ = "cody.shepherd@gmail.com"
__status__ = "Alpha"

SERVER_ID = str(uuid.uuid1())

LOG_NAME = "server.log"

log_handler = RotatingFileHandler(LOG_NAME, mode='w+', maxBytes = 1000000, backupCount=2, encoding=None, delay=0)
log_handler.setLevel(logging.DEBUG)

LOGGER = logging.getLogger('root')
LOGGER.setLevel(logging.DEBUG)
LOGGER.addHandler(log_handler)

DISPATCH_TABLE = {
    100: lambda x: handle_100(x),
    101: lambda x: handle_101(x),
    103: lambda x: handle_103(x),
    104: lambda x: handle_104(x),
    106: lambda x: handle_106(x),
    108: lambda x: handle_108(x),
    109: lambda x: handle_109(x),
    110: lambda x: handle_110(x),
    112: lambda x: handle_112(x)
}

CTRL = controller.Controller()
D_CONNS = []                    # List for timing out connections
UUID_SLICE = 4

async def handle(websocket, path):
    LOGGER.debug("handle called")
    global D_CONNS
    try:
        async for message in websocket:
            LOGGER.debug("Message received: " + str(message))

            await prune_dc()

            addr = websocket.remote_address
            #LOGGER.debug("Address of socket: " + str(addr[0]) + ':' + str(addr[1]))

            obj = json.loads(message)
            msgID = obj.get("messageID")
            srcID = obj.get("sourceID")
            #LOGGER.debug("Type of msgID: " + str(type(msgID)))

            if obj is None or msgID is None:
                LOGGER.debug("Error sent")
                await websocket.send(error_msg("ERROR: messageID must be provided"))
            elif ((not srcID) or (srcID == "clown shoes")) and msgID != 112:
                LOGGER.debug("No sourceID provided")
                errmsg = error_msg("Error: SrcID must be provided")
                LOGGER.debug("Message sent: " + str(errmsg))
                await websocket.send(errmsg)

            else:
                if msgID == 112:
                    obj['addr'] = addr
                else:
                    CTRL.set_TTL(srcID)

                LOGGER.debug("Dispatch table called")
                if srcID != "clown shoes":
                    CTRL.log_socket(srcID, websocket)
                msg = await DISPATCH_TABLE[msgID](obj)
                if msg:
                    #await websocket.send(DISPATCH_TABLE[msgID](obj))
                    LOGGER.debug("Message sent: " + str(msg))
                    await websocket.send(msg)

    except ConnectionClosed as e:
        addr = websocket.remote_address
        LOGGER.debug("Connection closed at: " + str(addr))

        cid = CTRL.get_cid_by_address(addr)
        nick = CTRL.clients.get(cid)
        if nick is None:
            nick = "NOT FOUND"

        if cid is None:
            LOGGER.error("No clientID found for connection at address " + str(addr))
            return

        if CTRL.check_TTL(cid):
            D_CONNS.append(cid)
            LOGGER.info("Client " + nick + '--' + str(cid[:UUID_SLICE]) + " dropped websocket connection.")
            return

        LOGGER.debug("Closed connection thrown by client " + nick + '--' + cid[:UUID_SLICE] + ". Exiting client now.")
        msg = {'sourceID': cid}
        await handle_106(msg)

async def prune_dc():
    """
    This function repeatedly checks the list of "timing out" connections to ensure that timed
    out connections get dropped.
    """
    global D_CONNS
    if D_CONNS == []:
        return

    for cid in D_CONNS:
        if not CTRL.check_TTL(cid):
            LOGGER.info(str(cid) + " has timed out and is being dropped.")
            msg = {'sourceID': cid}
            D_CONNS = [x for x in D_CONNS if x != cid]
            await handle_106(msg)
        
def make_msg(srcID, msgID, payload):
    """
    Helper function for generating well-formed json messages.

    :param srcID: the ID of this server, ideally
    :param msgID: the msgID as dictated by the RFC
    :param payload: The stuff to put in the payload, if any
    :return: a json-serialized message
    """
    LOGGER.debug("make_msg() started")
    msg = json.dumps({
        "sourceID": srcID,
        "messageID": msgID,
        "payload": payload
    })
    return msg

def error_msg(txt):
    """
    A Helper function for generating well-formed json error messages

    :param txt: the error string
    :return: a json-serialized message
    """
    LOGGER.debug("error_msg() started")
    msg = json.dumps({
        "sourceID": SERVER_ID,
        "messageID": 114,
        "payload": {'error': txt}

    })
    return msg

async def broadcast(msg, clients):
    """
    Broadcast a message to all clients
    :param msg: the well-formed json object to be broadcast
    :param clients: the list of UUIDs to which to send msg
    :return: None
    """
    LOGGER.debug("broadcast started")
    LOGGER.debug("broadcasting message: " + msg)
    LOGGER.debug("broadcasting to: " + str(clients))

    # Loop through all clients, sending 105, or 102 & 105 for the 101 initiator
    for cid in clients:
        nick = CTRL.clients.get(cid)
        if nick is None:
            nick = "NOT FOUND"
        sock = CTRL.get_socket(cid)
        if sock:
            #addr = sock.remote_address
            LOGGER.debug("Sending to client: " + nick + '--' + cid[:UUID_SLICE])
            await sock.send(msg)
            #crock = websockets.connect("ws://" + str(addr[0]) + ':' + str(addr[1]))
            #crock.send(msg)

    LOGGER.debug("Broadcast finished")

async def handle_100(msg):
    """
    Handler for msg code 101: Update Session

    Sends updates to all clients in the session's clientlists

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_100() started")

    cid = msg.get("sourceID")
    payload = msg.get("payload")

    if payload is None:
        LOGGER.error("No payload provided to handle_100")
        return error_msg("Error: no payload provided for msgID 100")

    sess = msg.get("payload").get("session")
    if sess is None:
        LOGGER.error("No session provided to handle_100()")
        return error_msg("Error: no session object provided for msgID 100")

    newsess =  CTRL.update_session(cid, sess)

    if newsess is not None:
        newmsg = make_msg(SERVER_ID, 100, {'session': newsess.export()})
        LOGGER.debug("Broadcasting " + newmsg + " to all of session's clients")

        await broadcast(newmsg, [x[0] for x in newsess.clientlist])

async def handle_101(msg):
    """
    Handler for msgID 101: Create Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_101(): Create Session started")
    cid = msg.get("sourceID")
    nick = CTRL.clients.get(cid)
    if nick is None:
        nick = "NOT FOUND"

    sessID = CTRL.new_session()

    LOGGER.info("Client " + nick + '--' + cid[:UUID_SLICE] + " created session " + str(sessID))

    sess = CTRL.get_session(sessID)
    newmsg = make_msg(SERVER_ID, 102, {'session': sess})

    sock = CTRL.get_socket(cid)
    LOGGER.debug("Sending " + str(newmsg) + " to client " + nick + '--' + str(cid[:UUID_SLICE]))
    await sock.send(newmsg)

    # For broadcasting session list to clients
    clients = list([x for x in CTRL.clients.keys()])       # UUIDs list
    sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list

    await broadcast(make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs}), clients)
    """
    if CTRL.client_join(cid, sessID):
        LOGGER.debug("Client " + nick + '--' + cid[:UUID_SLICE] + " joined session " + str(sessID))
        sess = CTRL.get_session(sessID)
        newmsg = make_msg(SERVER_ID, 102, {'session': sess})

        sock = CTRL.get_socket(cid)
        LOGGER.debug("Sending " + str(newmsg) + " to client " + nick + '--' + str(cid[:UUID_SLICE]))
        await sock.send(newmsg)

        # For broadcasting session list to clients
        clients = list([x for x in CTRL.clients.keys() if x != cid])       # UUIDs list
        sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list

        LOGGER.debug("Broadcasting " + str(msg) + " to all clients.")
        await broadcast(make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs}), clients)
    else:
        LOGGER.error("Client " + nick + '--' + cid[:UUID_SLICE] + " attempt to join session failed")
        return error_msg("Error: Could not join session.")
    """

async def handle_103(msg):
    """
    Handler for msgID 103: Join Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_103(): Join Session started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")

    if sid is None:
        LOGGER.error("sid not provided")
        return error_msg("Error: sessionID must be provided in payload")

    if CTRL.client_join(cid, sid):
        LOGGER.debug("Client " + cid + " joined session " + str(sid))

        sess = CTRL.sessions.get(sid)

        newmsg = make_msg(SERVER_ID, 100, {'session': sess.export()})
        LOGGER.debug("Broadcasting " + newmsg + " to all of session's clients")

        await broadcast(newmsg, [x[0] for x in sess.clientlist])

    else:
        LOGGER.error("Client " + cid + " attempt to join session " + str(sid) + " failed")
        return error_msg("Error: Could not join session")

async def handle_104(msg):
    """
    Handler for msgID 104: Leave Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_104(): Leave Session started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")

    if sid is None:
        LOGGER.error("sid not provided")
        return error_msg("Error: sessionID must be provided in payload")


    if CTRL.client_leave(cid, sid):
        LOGGER.debug("104: Client leave session successful")
    else:
        LOGGER.error("104: Leave session failed")

    clients = list(CTRL.clients.keys())       # UUIDs list
    sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list
    newmsg = make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs})
    await broadcast(newmsg, clients)

    newsess = CTRL.sessions.get(sid)

    if newsess:
        newmsg = make_msg(SERVER_ID, 100, {'session': newsess.export()})
        LOGGER.debug("Broadcasting " + newmsg + " to all of session's clients")

        await broadcast(newmsg, [x[0] for x in newsess.clientlist])

async def handle_106(msg):
    """
    Handler for msgID 106: Client Disconnect

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_106(): Client Disconnect started")

    cid = msg.get("sourceID")
    nick = CTRL.clients.get(cid)
    if nick is None:
        nick = "NOT FOUND"

    if cid is None:
        LOGGER.error("No clientID provided to handle_106()")
        return error_msg("Error: sourceID must be provided.")

    client_sessionIDs = CTRL.client_sessions.get(cid)

    if CTRL.client_exit(cid):
        LOGGER.debug(nick + ": Client disconnect successful")
    else:
        LOGGER.error(nick + ": Client disconnect failed")

    clients = list(CTRL.clients.keys())       # UUIDs list
    sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list
    newmsg = make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs})

    await broadcast(newmsg, clients)

    for sid in client_sessionIDs:
        sess = CTRL.sessions.get(sid)
        if sess is not None:
            upd = make_msg(SERVER_ID, 100, {'session': sess.export()})
            await broadcast(upd, [x[0] for x in sess.clientlist])

async def handle_108(msg):
    """
    Handler for msgID 108: Broadcast

    :param msg: the message dict
    :return: a json-serialized object, or None
    """
    LOGGER.debug("handle_108(): Broadcast started")

    cid = msg.get("sourceID")

    track = msg.get('payload').get("track")

    if track is None:
        LOGGER.error("No track provided")
        return error_msg("Error: track must be provided")

    sids = msg.get('payload').get("sessionIDs")

    if sids is None:
        LOGGER.error("No list of sessionIDs provided")
        return error_msg("Error: list of sessionIDs must be provided")

    sessions = CTRL.broadcast(cid, sids, track)

    for sess in sessions:
        newmsg = make_msg(SERVER_ID, 100, {'session': sess.export()})
        await broadcast(newmsg, [x[0] for x in sess.clientlist])

async def handle_109(msg):
    """
    Handler for msgID 109: Request Track

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_109(): Request Track started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")
    tid = msg.get("payload").get("trackID")

    trid, ssid, yn = CTRL.request_track(cid, sid, tid)

    if trid is None:
        newmsg = error_msg("Error: request_track failed")
    else:
        newmsg = make_msg(SERVER_ID, 111, {'status': yn, 'sessionID': ssid, 'trackID': trid})

    sock = CTRL.get_socket(cid)
    await sock.send(newmsg)

    session = CTRL.sessions.get(sid)

    if session is None:
        LOGGER.error("session " + str(sid) + " not found by handle_109() after calling CTRL.request_track()")
    else:
        bmsg = make_msg(SERVER_ID, 100, {'session': session.export()})
        await broadcast(bmsg, [x[0] for x in session.clientlist])

async def handle_110(msg):
    """
    Handler for msgID 110: Relinquish Track

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_110(): Relinquish Track started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")
    tid = msg.get("payload").get("trackID")

    if sid is None or tid is None:
        LOGGER.error("sid or tid not given in message")
        return error_msg("Error: sessionID and trackID required")

    sock = CTRL.get_socket(cid)

    if CTRL.relinquish_track(cid, sid, tid):
        LOGGER.debug("Client " + str(cid) + " relinquished track " + str(sid) + ':' + str(tid))
        #sock.send(make_msg(SERVER_ID, 100, {'session': CTRL.get_session(sid)}))
    else:
        LOGGER.error("Client " + str(cid) + " failed to relinquish track " + str(sid) + ':' + str(tid))
        #sock.send(error_msg("Error: Failed to relinquish track"))

    sess = CTRL.sessions.get(sid)
    if sess is None:
        LOGGER.error("Session " + str(sid) + " not found by handle_110() after calling CTRL.relinquish_track()")
    else:
        await broadcast(make_msg(SERVER_ID, 100, {'session': sess.export()}), [x[0] for x in sess.clientlist])


async def handle_112(msg):
    """
    Handler for msgID 112: Client Connect

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_112():Client Connect started")

    addr = msg.get('addr')

    cid = CTRL.get_cid_by_address(addr)

    if cid:
        LOGGER.debug("Duplicate 112 detected from host " + str(addr))
        return make_msg(SERVER_ID, 113, {'clientID': cid, 'sessionIDs': list(CTRL.sessions.keys())})

    # No check for sourceID in this function b/c a new Client will not yet have one
    nick = msg.get("payload").get('nickname')

    if nick is None:
        LOGGER.error("Client did not provide nickname")
        return error_msg("Error: Nickname not provided")

    clientID = CTRL.new_client(nick)
    CTRL.log_cid_by_address(clientID, addr)
    CTRL.set_TTL(clientID)
    LOGGER.debug("New client ID: " + clientID + " assigned to " + str(addr))

    return make_msg(SERVER_ID, 113, {'clientID':clientID, 'sessionIDs': list(CTRL.sessions.keys())})

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Initialize Server")
    #parser.add_argument('-t', '--test', action='store_true', help='Port to listen on.')
    parser.add_argument('-p', '--port', help='Port to serve on')
    nspace = vars(parser.parse_args())
    #testing = nspace.get('test')
    port = nspace.get('port')
    if port is None:
        port = 8795
    LOGGER.debug("websocket server started on port " + str(port))
    asyncio.get_event_loop().run_until_complete(
        websockets.serve(handle, 'localhost', port))
    asyncio.get_event_loop().run_forever()

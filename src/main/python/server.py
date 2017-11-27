# noinspection PyInterpreter,PyInterpreter
import asyncio
import websockets
import json
import controller
import logging
import uuid
import os
import argparse

SERVER_ID = str(uuid.uuid1())

LOG_NAME = "server.log"

#if os.path.isfile(LOG_NAME):
#    os.remove(LOG_NAME)

LOGGER = logging.getLogger(LOG_NAME)
logging.basicConfig(filename=LOG_NAME,level=logging.DEBUG)

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

async def handle(websocket, path):
    LOGGER.debug("handle called")
    async for message in websocket:
        LOGGER.debug("Message received: " + str(message))

        addr = websocket.remote_address
        #LOGGER.debug("Address of socket: " + str(addr[0]) + ':' + str(addr[1]))

        obj = json.loads(message)
        msgID = obj.get("messageID")
        srcID = obj.get("sourceID")
        #LOGGER.debug("Type of msgID: " + str(type(msgID)))

        if not (obj and msgID):
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

            LOGGER.debug("Dispatch table called")
            if srcID != "clown shoes":
                CTRL.log_socket(srcID, websocket)
            msg = DISPATCH_TABLE[msgID](obj)
            if msg:
                #await websocket.send(DISPATCH_TABLE[msgID](obj))
                LOGGER.debug("Message sent: " + str(msg))
                await websocket.send(msg)

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

def broadcast(msg, clients):
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
        sock = CTRL.get_socket(cid)
        if sock:
            #addr = sock.remote_address
            LOGGER.debug("Sending to client: " + cid)
            sock.send(msg)
            #crock = websockets.connect("ws://" + str(addr[0]) + ':' + str(addr[1]))
            #crock.send(msg)

    LOGGER.debug("Broadcast finished")
    return None

def handle_100(msg):
    """
    Handler for msg code 101: Update Session

    Sends updates to all clients in the session's clientlists

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_100() started")

    cid = msg.get("sourceID")
    payload = msg.get("payload")

    if not payload:
        LOGGER.error("No payload provided to handle_100")
        return error_msg("Error: no payload provided for msgID 100")

    sess = msg.get("payload").get("session")
    if not sess:
        LOGGER.error("No session provided to handle_100()")
        return error_msg("Error: no session object provided for msgID 100")

    newsess =  CTRL.update_session(cid, sess)

    newmsg = make_msg(SERVER_ID, 100, {'session': newsess.export()})
    LOGGER.debug("Broadcasting " + newmsg + " to all of session's clients")

    return broadcast(newmsg, [x[0] for x in newsess.clientlist])

def handle_101(msg):
    """
    Handler for msgID 101: Create Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_101(): Create Session started")
    cid = msg.get("sourceID")

    sessID = CTRL.new_session()
    if CTRL.client_join(cid, sessID):
        LOGGER.debug("Client " + cid + " joined session " + str(sessID))
        sess = CTRL.get_session(sessID)
        newmsg = make_msg(SERVER_ID, 102, {'session': sess})

        sock = CTRL.get_socket(cid)
        LOGGER.debug("Sending " + str(newmsg) + " to client " + str(cid))
        sock.send(newmsg)

        # For broadcasting session list to clients
        clients = list([x for x in CTRL.clients.keys() if x != cid])       # UUIDs list
        sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list

        LOGGER.debug("Broadcasting " + str(msg) + " to all clients.")
        return broadcast(make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs}), clients)
    else:
        LOGGER.error("Client " + cid + " attempt to join session failed")
        return error_msg("Error: Could not join session.")

def handle_103(msg):
    """
    Handler for msgID 103: Join Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_103(): Join Session started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")

    if not sid:
        LOGGER.error("sid not provided")
        return error_msg("Error: sessionID must be provided in payload")

    if CTRL.client_join(cid, sid):
        LOGGER.debug("Client " + cid + " joined session " + str(sid))

        sess = CTRL.sessions.get(sid)

        newmsg = make_msg(SERVER_ID, 100, {'session': sess.export()})
        LOGGER.debug("Broadcasting " + newmsg + " to all of session's clients")

        return broadcast(newmsg, [x[0] for x in sess.clientlist])

    else:
        LOGGER.error("Client " + cid + " attempt to join session " + str(sid) + " failed")
        return error_msg("Error: Could not join session")

def handle_104(msg):
    """
    Handler for msgID 104: Leave Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_104(): Leave Session started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")

    if not sid:
        LOGGER.error("sid not provided")
        return error_msg("Error: sessionID must be provided in payload")

    clients = list(CTRL.clients.keys())       # UUIDs list
    sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list
    newmsg = make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs})

    if CTRL.client_leave(cid, sid):
        LOGGER.debug("104: Client leave session successful")
    else:
        LOGGER.error("104: Leave session failed")

    return broadcast(newmsg, clients)

def handle_106(msg):
    """
    Handler for msgID 106: Client Disconnect

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_106(): Client Disconnect started")

    cid = msg.get("sourceID")

    clients = list(CTRL.clients.keys())       # UUIDs list
    sessionIDs = list(CTRL.sessions.keys())   # sessionIDs list
    newmsg = make_msg(SERVER_ID, 105, {'sessionIDs': sessionIDs})

    if CTRL.client_exit(cid):
        LOGGER.debug("Client disconnect successful")
    else:
        LOGGER.error("Client disconnect failed")

    return broadcast(newmsg, clients)

def handle_108(msg):
    """
    Handler for msgID 108: Broadcast

    :param msg: the message dict
    :return: a json-serialized object, or None
    """
    LOGGER.debug("handle_108(): Broadcast started")

    cid = msg.get("sourceID")

    track = msg.get("track")

    if not track:
        LOGGER.error("No track provided")
        return error_msg("Error: track must be provided")

    sids = msg.get("sessionIDs")

    if not sids:
        LOGGER.error("No list of sessionIDs provided")
        return error_msg("Error: list of sessionIDs must be provided")

    sessions = CTRL.broadcast(cid, sids, track)

    for sess in sessions:
        newmsg = make_msg(SERVER_ID, 100, {'session': sess.export()})
        broadcast(newmsg, [x[0] for x in sess.clientlist])

    return None

def handle_109(msg):
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

    if trid == None:
        newmsg = error_msg("Error: request_track failed")
    else:
        newmsg = make_msg(SERVER_ID, 111, {'status': yn, 'sessionID': ssid, 'trackID': trid})

    sock = CTRL.get_socket(cid)
    sock.send(newmsg)

    session = CTRL.sessions.get(sid)

    bmsg = make_msg(SERVER_ID, 100, {'session': session.export()})

    return broadcast(bmsg, [x[0] for x in session.clientlist])

def handle_110(msg):
    """
    Handler for msgID 110: Relinquish Track

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_110(): Relinquish Track started")

    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")
    tid = msg.get("payload").get("trackID")

    if not (sid and tid):
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
    return broadcast(make_msg(SERVER_ID, 100, {'session': sess.export()}), [x[0] for x in sess.clientlist])


def handle_112(msg):
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

    if not nick:
        LOGGER.error("Client did not provide nickname")
        return error_msg("Error: Nickname not provided")

    clientID = CTRL.new_client(nick)
    CTRL.log_cid_by_address(clientID, addr)
    LOGGER.debug("New client ID: " + clientID + " assigned to " + str(addr))

    return make_msg(SERVER_ID, 113, {'clientID':clientID, 'sessionIDs': list(CTRL.sessions.keys())})

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Initialize Server")
    #parser.add_argument('-t', '--test', action='store_true', help='Port to listen on.')
    parser.add_argument('-p', '--port', help='Port to serve on')
    nspace = vars(parser.parse_args())
    #testing = nspace.get('test')
    port = nspace.get('port')
    if not port:
        port = 8795
    LOGGER.debug("websocket server started on port " + str(port))
    asyncio.get_event_loop().run_until_complete(
        websockets.serve(handle, 'localhost', port))
    asyncio.get_event_loop().run_forever()

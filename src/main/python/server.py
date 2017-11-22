import asyncio
import websockets
import json
import controller
import logging
import uuid
import os

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
        elif not srcID:
            LOGGER.debug("No sourceID provided")
            await websocket.send(error_msg("ERROR: srcID must be provided"))
        else:
            LOGGER.debug("Dispatch table called")
            CTRL.log_socket(srcID, websocket)
            msg = DISPATCH_TABLE[msgID](obj)
            LOGGER.debug("Message sent: " + msg)
            if msg:
                await websocket.send(DISPATCH_TABLE[msgID](obj))

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
    msg = json.dumps({
        "sourceID": SERVER_ID,
        "messageID": 114,
        "payload": {'error': txt}

    })
    return msg

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
    for cid, nick in newsess.clientlist:
        sock = CTRL.get_socket(cid)
        sock.send(newmsg)

    return newmsg


def handle_101(msg):
    """
    Handler for msgID 101: Create Session

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_101(): Create Session started")
    src_client = msg.get("sourceID")

    sessID = CTRL.new_session()
    if CTRL.client_join(src_client, sessID):
        LOGGER.debug("Client " + src_client + " joined session " + str(sessID))
        sess = CTRL.get_session(sessID)
        newmsg = make_msg(SERVER_ID, 102, {'session': sess})

    else:
        LOGGER.error("Client " + src_client + " attempt to join session failed")
        newmsg = error_msg("Error: Could not join session.")

    return newmsg

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
        newmsg = make_msg(SERVER_ID, 100, {'session': CTRL.get_session(sid)})

    else:
        LOGGER.error("Client " + cid + " attempt to join session " + str(sid) + " failed")
        newmsg = error_msg("Error: Could not join session")

    return newmsg

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

    if CTRL.client_leave(cid, sid):
        newmsg = make_msg(SERVER_ID, 105, {'sessionIDs': CTRL.client_sessions[cid]})
    else:
        newmsg = error_msg("Error: Leave session failed")

    return newmsg

def handle_106(msg):
    """
    Handler for msgID 106: Client Disconnect

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.debug("handle_106(): Client Disconnect started")

    cid = msg.get("sourceID")

    if CTRL.client_exit(cid):
        LOGGER.debug("Client disconnect successful")
    else:
        LOGGER.error("Client disconnect failed")

    return None

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
        for ccid,nick in sess.clientlist:
            if ccid != cid:
                sock = CTRL.get_socket(ccid)
                sock.send(make_msg(SERVER_ID, 100, {'session': sess.export()}))

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

    if not trid:
        newmsg = error_msg("Error: request_track failed")
    else:
        newmsg = make_msg(SERVER_ID, 111, {'status': yn, 'sessionID': ssid, 'trackID': trid})

    return newmsg

def handle_110(msg):
    """
    Handler for msgID 110: Relinquish Track

    :param msg: the message dict
    :return: a json-serialized object
    """
    cid = msg.get("sourceID")
    sid = msg.get("payload").get("sessionID")
    tid = msg.get("payload").get("trackID")

    if not (sid and tid):
        LOGGER.error("sid or tid not given in message")
        return error_msg("Error: sessionID and trackID required")

    if CTRL.relinquish_track(cid, sid, tid):
        LOGGER.debug("Client " + str(cid) + " relinquished track " + str(sid) + ':' + str(tid))
        return make_msg(SERVER_ID, 100, {'session': CTRL.get_session(sid)})
    else:
        LOGGER.error("Client " + str(cid) + " failed to relinquish track " + str(sid) + ':' + str(tid))
        return error_msg("Error: Failed to relinquish track")


def handle_112(msg):
    """
    Handler for msgID 112: Client Connect

    :param msg: the message dict
    :return: a json-serialized object
    """
    LOGGER.info("handle_112():Client Connect started")

    # No check for sourceID in this function b/c a new Client will not yet have one
    nick = msg.get("payload").get('nickname')

    if not nick:
        LOGGER.error("Client did not provide nickname")
        return error_msg("Error: Nickname not provided")

    clientID = CTRL.new_client(nick)
    LOGGER.info("New client ID: " + clientID)

    return make_msg(SERVER_ID, 113, {'clientID':clientID})


LOGGER.info("websocket server started")
asyncio.get_event_loop().run_until_complete(
    websockets.serve(handle, 'localhost', 8795))
asyncio.get_event_loop().run_forever()

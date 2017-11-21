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
    109: lambda x: handle_109(x),
    110: lambda x: handle_110(x),
    112: lambda x: handle_112(x)
}

CTRL = controller.Controller()

async def handle(websocket, path):
    LOGGER.info("handle called")
    async for message in websocket:
        LOGGER.info("Message received: " + str(message))
        #await websocket.send(message)
        addr = websocket.remote_address()
        obj = json.loads(message)
        msgID = obj.get("messageID")
        srcID = obj.get("sourceID")
        LOGGER.info("Type of msgID: " + str(type(msgID)))
        if not (obj and msgID):
            LOGGER.info("Error sent")
            await websocket.send(error_msg("ERROR: messageID must be provided"))
        elif not srcID:
            LOGGER.info("No sourceID provided")
            await websocket.send(error_msg("ERROR: srcID must be provided"))
        else:
            LOGGER.info("Dispatch table called")
            CTRL.log_socket(srcID, addr)
            await websocket.send(DISPATCH_TABLE[msgID](obj))

def make_msg(srcID, msgID, payload):
    msg = json.dumps({
        "sourceID": srcID,
        "messageID": msgID,
        "payload": payload
    })
    return msg

def error_msg(txt):
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

    returns a json-serialized object
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
    Handler for msg code 101: Create session

    Returns an appropriate json-serialized object
    """
    LOGGER.info("handle_101(): Create Session started")
    src_client = msg.get("sourceID")
    if not src_client:
        LOGGER.error("Client did not provide sourceID")
        return error_msg("Error: sourceID must be provided")

    sessID = CTRL.new_session()
    if CTRL.client_join(src_client, sessID):
        LOGGER.info("Client " + src_client + " joined session " + str(sessID))
        msg = make_msg(SERVER_ID, 102, {'session': CTRL.get_session(sessID)})

    else:
        LOGGER.error("Client " + src_client + " attempt to join session failed")
        msg = error_msg("Error: Could not join session.")

    return msg

def handle_109(msg):
    """
    Handler for msgID 109: Request Track

    :param msg:
    :return:
    """
    pass

def handle_110(msg):
    """
    Handler for msgID 110: Relinquish Track
    :param msg:
    :return:
    """
    pass

def handle_112(msg):
    """
    Handler for msgID 112: Client Connect
    
    returns an appropriate json-serialized object
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

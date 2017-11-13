import asyncio
import websockets
import json
import controller
import logging
import uuid

SERVER_ID = str(uuid.uuid1())

LOG_NAME = "server.log"
LOGGER = logging.getLogger(LOG_NAME)

DISPATCH_TABLE = {
    101: lambda x: handle_101(x)
}

CTRL = Controller()

async def handle(websocket, path):
    async for message in websocket:
        obj = json.loads(message)
        msgID = obj.get("messageID")
        if not msgID:
            await websocket.send("ERROR: messageID must be provided")
        else:
            await websocket.send(DISPATCH_TABLE[msgID](obj))

def make_msg(srcID, msgID, payload):
    msg = json.dumps({
        "sourceID": srcID,
        "messageID": msgID,
        "payload": payload
    })
    return msg

def handle_101(msg):
    """
    Handler for msg code 101: Create session

    Returns an appropriate json-serialized object
    """
    src_client = msg.get("sourceID")
    if not src_client:
        return "Error: sourceID must be provided"

    sessID = CTRL.new_session()
    if CTRL.client_join(src_client, sessID):
        LOGGER.info("Client " + src_client + " joined session " + str(sessID))
        msg = make_msg(srcID, 102, CTRL.get_session(sessID))
    else:
        LOGGER.error("Client " + src_client + " attempt to join session failed")

import asyncio
import websockets
import json
import controller
import logging
import uuid
import os



SERVER_ID = str(uuid.uuid1())

LOG_NAME = "server.log"
os.remove(LOG_NAME)

LOGGER = logging.getLogger(LOG_NAME)
logging.basicConfig(filename=LOG_NAME,level=logging.DEBUG)

DISPATCH_TABLE = {
    101: lambda x: handle_101(x)
}

CTRL = controller.Controller()

async def handle(websocket, path):
    LOGGER.info("handle called")
    async for message in websocket:
        LOGGER.info("Message received: " + str(message))
        #await websocket.send(message)
        obj = json.loads(message)
        msgID = obj.get("messageID")
        if not (obj or msgID):
            LOGGER.info("Error sent")
            await websocket.send("ERROR: messageID must be provided")
        else:
            LOGGER.info("Dispatch table called")
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

LOGGER.info("websocket server started")
asyncio.get_event_loop().run_until_complete(
    websockets.serve(handle, 'localhost', 8795))
asyncio.get_event_loop().run_forever()

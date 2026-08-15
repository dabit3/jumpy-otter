#!/usr/bin/env python3
"""Tiny WebSocket relay for Jumpy Otter multiplayer.

Groups the first connecting clients (up to 4) into a room and forwards each
message to the other members, tagged with the sender's player id.

Usage:
    pip install websockets
    python3 relay.py            # listens on ws://127.0.0.1:8765

On real devices, run this on a host reachable over the network and point the
clients at its LAN IP instead of 127.0.0.1.
"""

import asyncio
import json
import signal

import websockets

HOST = "127.0.0.1"
PORT = 8765
ROOM_SIZE = 4


class Room:
    def __init__(self):
        self.clients = {}  # player_id -> websocket

    def free_id(self):
        for pid in range(ROOM_SIZE):
            if pid not in self.clients:
                return pid
        return None


rooms = []


def find_room():
    for room in rooms:
        if room.free_id() is not None:
            return room
    room = Room()
    rooms.append(room)
    return room


async def send(ws, payload):
    try:
        await ws.send(json.dumps(payload))
    except websockets.ConnectionClosed:
        pass


async def broadcast(room, sender_id, payload):
    for pid, ws in list(room.clients.items()):
        if pid != sender_id:
            await send(ws, payload)


async def handler(ws):
    room = find_room()
    player_id = room.free_id()
    room.clients[player_id] = ws
    print(f"player {player_id} joined (room of {len(room.clients)})")

    await send(ws, {
        "type": "welcome",
        "id": player_id,
        "players": [pid for pid in room.clients if pid != player_id],
    })
    await broadcast(room, player_id, {"type": "playerJoined", "id": player_id})

    try:
        async for raw in ws:
            try:
                msg = json.loads(raw)
            except (json.JSONDecodeError, TypeError):
                continue
            if not isinstance(msg, dict):
                continue
            msg["id"] = player_id
            await broadcast(room, player_id, msg)
    except websockets.ConnectionClosed:
        pass
    finally:
        room.clients.pop(player_id, None)
        print(f"player {player_id} left (room of {len(room.clients)})")
        await broadcast(room, player_id, {"type": "opponentLeft", "id": player_id})
        if not room.clients and room in rooms:
            rooms.remove(room)


async def main():
    stop = asyncio.get_running_loop().create_future()
    for sig in (signal.SIGINT, signal.SIGTERM):
        asyncio.get_running_loop().add_signal_handler(sig, lambda: stop.set_result(None))
    async with websockets.serve(handler, HOST, PORT):
        print(f"relay listening on ws://{HOST}:{PORT}")
        await stop


if __name__ == "__main__":
    asyncio.run(main())

#!/usr/bin/env python3
"""Integration test for relay.py.

Starts two clients against a running relay (ws://127.0.0.1:8765) and checks
welcome, playerJoined, state, garbage, gameOver, and opponentLeft handling.

Usage:
    .relay-venv/bin/python relay.py &         # start the relay first
    .relay-venv/bin/python scripts/test_relay.py
"""

import asyncio
import json

import websockets

URL = "ws://127.0.0.1:8765"


async def recv(ws):
    return json.loads(await asyncio.wait_for(ws.recv(), timeout=5))


async def main():
    a = await websockets.connect(URL)
    b = await websockets.connect(URL)

    welcome_a = await recv(a)
    welcome_b = await recv(b)
    assert welcome_a["type"] == "welcome"
    assert welcome_b["type"] == "welcome"
    assert welcome_a["id"] != welcome_b["id"]
    assert welcome_a["id"] in welcome_b["players"]

    joined = await recv(a)
    assert joined == {"type": "playerJoined", "id": welcome_b["id"]}

    await a.send(json.dumps({"type": "state", "row": 5, "x": 1.0, "score": 5, "alive": True}))
    state = await recv(b)
    assert state["type"] == "state" and state["id"] == welcome_a["id"]
    assert state["row"] == 5 and state["alive"] is True

    # malformed messages must be ignored, not crash the relay
    await a.send("not json")
    await a.send(json.dumps(["not", "a", "dict"]))

    await b.send(json.dumps({"type": "garbage", "amount": 2}))
    garbage = await recv(a)
    assert garbage["type"] == "garbage" and garbage["amount"] == 2 and garbage["id"] == welcome_b["id"]

    await b.send(json.dumps({"type": "gameOver", "score": 12}))
    game_over = await recv(a)
    assert game_over["type"] == "gameOver" and game_over["score"] == 12

    await b.close()
    left = await recv(a)
    assert left == {"type": "opponentLeft", "id": welcome_b["id"]}

    await a.close()
    print("all relay checks passed")


if __name__ == "__main__":
    asyncio.run(main())

package com.devin.jumpyotter

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.TimeUnit

sealed class MultiplayerEvent {
    data class Connected(val playerID: Int, val peers: List<Int>) : MultiplayerEvent()
    data class PeerJoined(val id: Int) : MultiplayerEvent()
    data class PeerState(val id: Int, val row: Int, val x: Float, val score: Int, val alive: Boolean) : MultiplayerEvent()
    data class PeerGarbage(val id: Int, val amount: Int) : MultiplayerEvent()
    data class PeerGameOver(val id: Int, val score: Int) : MultiplayerEvent()
    data class OpponentLeft(val id: Int) : MultiplayerEvent()
    object Disconnected : MultiplayerEvent()
}

/**
 * WebSocket client for relay.py. Speaks the same JSON protocol as the iOS app.
 * Events are queued and drained on the game thread via [poll].
 */
class MultiplayerClient(private val url: String = DEFAULT_URL) {

    private val http = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()
    private var socket: WebSocket? = null
    private val events = ConcurrentLinkedQueue<MultiplayerEvent>()

    @Volatile var connected = false
        private set
    @Volatile var playerID = -1
        private set

    fun connect() {
        if (socket != null) return
        val request = Request.Builder().url(url).build()
        socket = http.newWebSocket(request, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) = handle(text)

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                connected = false
                socket = null
                events.add(MultiplayerEvent.Disconnected)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                connected = false
                socket = null
                events.add(MultiplayerEvent.Disconnected)
            }
        })
    }

    fun disconnect() {
        socket?.close(1000, null)
        socket = null
        connected = false
    }

    fun poll(): MultiplayerEvent? = events.poll()

    fun sendState(row: Int, x: Float, score: Int, alive: Boolean) {
        send(JSONObject().put("type", "state").put("row", row).put("x", x.toDouble()).put("score", score).put("alive", alive))
    }

    fun sendGarbage(amount: Int) {
        send(JSONObject().put("type", "garbage").put("amount", amount))
    }

    fun sendGameOver(score: Int) {
        send(JSONObject().put("type", "gameOver").put("score", score))
    }

    private fun send(obj: JSONObject) {
        if (!connected) return
        socket?.send(obj.toString())
    }

    private fun handle(text: String) {
        val obj = try { JSONObject(text) } catch (e: Exception) { return }
        when (obj.optString("type")) {
            "welcome" -> {
                playerID = obj.optInt("id", -1)
                connected = true
                events.add(MultiplayerEvent.Connected(playerID, intList(obj.optJSONArray("peers"))))
            }
            "peerJoined" -> events.add(MultiplayerEvent.PeerJoined(obj.optInt("id")))
            "state" -> events.add(
                MultiplayerEvent.PeerState(
                    obj.optInt("id"), obj.optInt("row"), obj.optDouble("x", 0.0).toFloat(),
                    obj.optInt("score"), obj.optBoolean("alive", true),
                )
            )
            "garbage" -> events.add(MultiplayerEvent.PeerGarbage(obj.optInt("id"), obj.optInt("amount", 1)))
            "gameOver" -> events.add(MultiplayerEvent.PeerGameOver(obj.optInt("id"), obj.optInt("score")))
            "opponentLeft" -> events.add(MultiplayerEvent.OpponentLeft(obj.optInt("id")))
        }
    }

    private fun intList(arr: JSONArray?): List<Int> {
        if (arr == null) return emptyList()
        return (0 until arr.length()).map { arr.optInt(it) }
    }

    companion object {
        /** 10.0.2.2 is the emulator's alias for the host loopback, where relay.py listens. */
        const val DEFAULT_URL = "ws://10.0.2.2:8765"
    }
}

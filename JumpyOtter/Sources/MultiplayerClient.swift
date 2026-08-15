import Foundation

/// Events the relay can deliver, surfaced to the game on an internal queue.
enum MultiplayerEvent {
    case connected(playerID: Int, peers: [Int])
    case peerJoined(id: Int)
    case peerState(id: Int, row: Int, x: Float, score: Int, alive: Bool)
    case peerGarbage(id: Int, amount: Int)
    case peerGameOver(id: Int, score: Int)
    case opponentLeft(id: Int)
    case disconnected
}

/// WebSocket client for the relay server (relay.py).
///
/// Exchanges small JSON messages: "state" (position + score, sent on every
/// change), "garbage" (hazard attack on rivals), "gameOver" (topped out) and
/// relay-generated "welcome" / "playerJoined" / "opponentLeft".
final class MultiplayerClient: NSObject {

    static let defaultURL = URL(string: "ws://127.0.0.1:8765")!

    private(set) var playerID: Int = -1
    private(set) var isConnected = false

    private let url: URL
    private var task: URLSessionWebSocketTask?
    private var session: URLSession!
    private var pingTimer: Timer?

    // Events are queued here and drained by the game on its render thread.
    private let eventLock = NSLock()
    private var pendingEvents: [MultiplayerEvent] = []

    init(url: URL = MultiplayerClient.defaultURL) {
        self.url = url
        super.init()
        session = URLSession(configuration: .default)
    }

    // MARK: - Connection

    func connect() {
        guard task == nil else { return }
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        receiveLoop()
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                self?.task?.sendPing { _ in }
            }
        }
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
    }

    /// Drains queued events; call from the game loop.
    func drainEvents() -> [MultiplayerEvent] {
        eventLock.lock()
        let events = pendingEvents
        pendingEvents.removeAll()
        eventLock.unlock()
        return events
    }

    // MARK: - Outgoing messages

    func sendState(row: Int, x: Float, score: Int, alive: Bool) {
        sendJSON([
            "type": "state",
            "row": row,
            "x": Double(x),
            "score": score,
            "alive": alive,
        ])
    }

    func sendGarbage(amount: Int) {
        sendJSON(["type": "garbage", "amount": amount])
    }

    func sendGameOver(score: Int) {
        sendJSON(["type": "gameOver", "score": score])
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard isConnected,
              let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }

    // MARK: - Incoming messages

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message { self.handle(text) }
                self.receiveLoop()
            case .failure:
                if self.isConnected {
                    self.isConnected = false
                    self.enqueue(.disconnected)
                }
                self.task = nil
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let msg = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = msg["type"] as? String else { return }
        let id = msg["id"] as? Int ?? -1
        switch type {
        case "welcome":
            playerID = id
            isConnected = true
            let peers = msg["players"] as? [Int] ?? []
            enqueue(.connected(playerID: id, peers: peers))
        case "playerJoined":
            enqueue(.peerJoined(id: id))
        case "state":
            enqueue(.peerState(
                id: id,
                row: msg["row"] as? Int ?? 0,
                x: Float(msg["x"] as? Double ?? 0),
                score: msg["score"] as? Int ?? 0,
                alive: msg["alive"] as? Bool ?? true))
        case "garbage":
            enqueue(.peerGarbage(id: id, amount: msg["amount"] as? Int ?? 1))
        case "gameOver":
            enqueue(.peerGameOver(id: id, score: msg["score"] as? Int ?? 0))
        case "opponentLeft":
            enqueue(.opponentLeft(id: id))
        default:
            break
        }
    }

    private func enqueue(_ event: MultiplayerEvent) {
        eventLock.lock()
        pendingEvents.append(event)
        eventLock.unlock()
    }
}

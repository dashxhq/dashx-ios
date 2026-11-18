import Foundation
import Network

enum LoopbackServerError: Error {
    case didNotStart
}

private func startOnLoopback(_ parameters: NWParameters, accept: @escaping (NWConnection) -> Void) throws -> (NWListener, UInt16) {
    parameters.requiredInterfaceType = .loopback
    let listener = try NWListener(using: parameters, on: .any)
    let ready = DispatchSemaphore(value: 0)
    listener.stateUpdateHandler = { state in
        if case .ready = state { ready.signal() }
    }
    listener.newConnectionHandler = accept
    listener.start(queue: DispatchQueue(label: "com.dashx.smoke.loopback"))
    guard ready.wait(timeout: .now() + 5) == .success, let port = listener.port?.rawValue else {
        listener.cancel()
        throw LoopbackServerError.didNotStart
    }
    return (listener, port)
}

/// Answers each GraphQL POST with the JSON `respond` returns for its `operationName`.
final class LoopbackGraphQLServer {
    let port: UInt16
    private let listener: NWListener

    init(respond: @escaping (_ operationName: String) -> String) throws {
        (listener, port) = try startOnLoopback(.tcp) { connection in
            connection.start(queue: DispatchQueue(label: "com.dashx.smoke.graphql"))
            Self.read(connection, received: Data(), respond: respond)
        }
    }

    private static func read(_ connection: NWConnection, received: Data, respond: @escaping (String) -> String) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { chunk, _, isComplete, error in
            let received = received + (chunk ?? Data())
            if let body = requestBody(in: received) {
                reply(on: connection, json: respond(operationName(in: body)))
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                read(connection, received: received, respond: respond)
            }
        }
    }

    private static func requestBody(in request: Data) -> Data? {
        guard let headerEnd = request.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: request[..<headerEnd.lowerBound], as: UTF8.self)
        let contentLength = head.components(separatedBy: "\r\n").compactMap { line -> Int? in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, parts[0].lowercased() == "content-length" else { return nil }
            return Int(parts[1].trimmingCharacters(in: .whitespaces))
        }.first ?? 0
        let body = request[headerEnd.upperBound...]
        return body.count >= contentLength ? Data(body.prefix(contentLength)) : nil
    }

    private static func operationName(in body: Data) -> String {
        let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        return json?["operationName"] as? String ?? ""
    }

    private static func reply(on connection: NWConnection, json: String) {
        let body = Data(json.utf8)
        let head = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(head.utf8) + body, completion: .contentProcessed { _ in connection.cancel() })
    }
}

/// Acknowledges every `SUBSCRIBE` frame the way the realtime server does.
final class LoopbackRealtimeServer {
    let port: UInt16
    private let listener: NWListener

    init() throws {
        let parameters = NWParameters.tcp
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)
        (listener, port) = try startOnLoopback(parameters) { connection in
            connection.start(queue: DispatchQueue(label: "com.dashx.smoke.realtime"))
            Self.receive(on: connection)
        }
    }

    private static func receive(on connection: NWConnection) {
        connection.receiveMessage { content, _, _, error in
            guard error == nil, let content else {
                connection.cancel()
                return
            }
            if let channel = subscribedChannel(in: content) {
                send(["type": "SUBSCRIPTION_SUCCEEDED", "data": ["channel": channel]], on: connection)
            }
            receive(on: connection)
        }
    }

    private static func subscribedChannel(in frame: Data) -> String? {
        guard let json = (try? JSONSerialization.jsonObject(with: frame)) as? [String: Any],
              json["type"] as? String == "SUBSCRIBE"
        else { return nil }
        return (json["data"] as? [String: Any])?["channelName"] as? String
    }

    private static func send(_ frame: [String: Any], on connection: NWConnection) {
        guard let content = try? JSONSerialization.data(withJSONObject: frame) else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        connection.send(content: content, contentContext: context, isComplete: true, completion: .idempotent)
    }
}

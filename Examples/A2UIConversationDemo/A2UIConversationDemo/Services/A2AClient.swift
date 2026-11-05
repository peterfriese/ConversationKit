//
//  A2AClient.swift
//  A2UIConversationDemo
//
//  A2A JSON-RPC client connecting to local A2UI agent servers
//  (e.g., `samples/agent/node/restaurant_finder` or `samples/agent/adk/restaurant_finder`
//  at http://localhost:10002/a2a/json-rpc).
//

import Foundation

public struct A2ATurnResponse: Sendable {
  public let contextID: String?
  public let textParts: [String]
  public let a2uiJSONMessages: [String]
  public let taskState: String?
}

public struct A2AActionPayload: Sendable {
  public let name: String
  public let surfaceID: String
  public let sourceComponentID: String
  public let contextJSONObject: [String: Any]

  public init(
    name: String,
    surfaceID: String,
    sourceComponentID: String,
    contextJSONObject: [String: Any]
  ) {
    self.name = name
    self.surfaceID = surfaceID
    self.sourceComponentID = sourceComponentID
    self.contextJSONObject = contextJSONObject
  }
}

public enum A2AClientError: LocalizedError, Sendable {
  case invalidEndpoint(String)
  case serverUnreachable(String)
  case rpcError(String)

  public var errorDescription: String? {
    switch self {
    case .invalidEndpoint(let url):
      return "Invalid A2A server URL: \(url)"
    case .serverUnreachable(let detail):
      return "Could not reach local A2UI Agent server (\(detail)). Start it with:\n`STUB_LLM=true yarn workspace @a2ui/agent-restaurant-node run start`"
    case .rpcError(let msg):
      return "A2A Agent error: \(msg)"
    }
  }
}

public enum A2AClient {
  /// Sends a text message or A2UI action to an A2A JSON-RPC server (`http://localhost:10002/a2a/json-rpc`)
  /// using `message/stream` and parses SSE / JSON-RPC status events.
  public static func sendTurn(
    endpointURLString: String,
    contextID: String?,
    text: String?,
    action: A2AActionPayload? = nil
  ) async throws -> A2ATurnResponse {
    let trimmedBase = endpointURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    let fullURLString: String
    if trimmedBase.hasSuffix("/a2a/json-rpc") {
      fullURLString = trimmedBase
    } else if trimmedBase.hasSuffix("/") {
      fullURLString = "\(trimmedBase)a2a/json-rpc"
    } else {
      fullURLString = "\(trimmedBase)/a2a/json-rpc"
    }

    guard let url = URL(string: fullURLString) else {
      throw A2AClientError.invalidEndpoint(endpointURLString)
    }

    var parts: [[String: Any]] = []
    if let text, !text.isEmpty {
      parts.append([
        "kind": "text",
        "text": text,
      ])
    }
    if let action {
      parts.append([
        "kind": "data",
        "data": [
          "version": "1.0",
          "action": [
            "name": action.name,
            "surfaceId": action.surfaceID,
            "sourceComponentId": action.sourceComponentID,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "context": action.contextJSONObject,
          ],
        ],
      ])
    }

    var messageDict: [String: Any] = [
      "kind": "message",
      "messageId": UUID().uuidString,
      "role": "user",
      "parts": parts,
      "metadata": [
        "a2uiRendererCapabilities": [
          "1.0": [
            "supportedCatalogIds": [
              A2UISystemPrompt.v10CatalogURI
            ]
          ]
        ]
      ],
    ]
    if let contextID {
      messageDict["contextId"] = contextID
    }

    let requestBody: [String: Any] = [
      "jsonrpc": "2.0",
      "id": Int.random(in: 1...99_999),
      "method": "message/stream",
      "params": [
        "message": messageDict
      ],
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 30
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.shared.data(for: request)
    } catch {
      throw A2AClientError.serverUnreachable(error.localizedDescription)
    }

    if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
      throw A2AClientError.serverUnreachable("HTTP \(httpResponse.statusCode)")
    }

    guard let rawBody = String(data: data, encoding: .utf8) else {
      throw A2AClientError.rpcError("Empty response from A2A server.")
    }

    return try parseA2AStreamOrJSONResponse(rawBody)
  }

  /// Parses SSE (`data: {...}`) lines or a single JSON-RPC envelope into text parts and A2UI JSON messages.
  private static func parseA2AStreamOrJSONResponse(_ rawBody: String) throws -> A2ATurnResponse {
    var discoveredContextID: String?
    var textParts: [String] = []
    var a2uiMessages: [String] = []
    var lastState: String?

    let lines = rawBody.components(separatedBy: .newlines)
    var jsonPayloads: [String] = []

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.hasPrefix("data:") {
        let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !payload.isEmpty {
          jsonPayloads.append(payload)
        }
      } else if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
        jsonPayloads.append(trimmed)
      }
    }

    for payload in jsonPayloads {
      guard
        let payloadData = payload.data(using: .utf8),
        let envelope = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
      else {
        continue
      }

      if let errorObj = envelope["error"] as? [String: Any],
        let errMsg = errorObj["message"] as? String
      {
        throw A2AClientError.rpcError(errMsg)
      }

      guard let result = envelope["result"] as? [String: Any] else { continue }

      if let cid = result["contextId"] as? String {
        discoveredContextID = cid
      }

      if let status = result["status"] as? [String: Any] {
        if let state = status["state"] as? String {
          lastState = state
        }
        if let message = status["message"] as? [String: Any],
          let parts = message["parts"] as? [[String: Any]]
        {
          extractParts(parts, intoText: &textParts, intoA2UI: &a2uiMessages)
        }
      } else if let parts = result["parts"] as? [[String: Any]] {
        extractParts(parts, intoText: &textParts, intoA2UI: &a2uiMessages)
      }
    }

    if lastState == "failed", let firstText = textParts.first {
      throw A2AClientError.rpcError(firstText)
    }

    return A2ATurnResponse(
      contextID: discoveredContextID,
      textParts: textParts,
      a2uiJSONMessages: a2uiMessages,
      taskState: lastState
    )
  }

  private static func extractParts(
    _ parts: [[String: Any]],
    intoText textParts: inout [String],
    intoA2UI a2uiMessages: inout [String]
  ) {
    for part in parts {
      let kind = part["kind"] as? String
      if kind == "text", let text = part["text"] as? String, !text.isEmpty {
        textParts.append(text)
      } else if kind == "data", let dataObj = part["data"] {
        if let dataDict = dataObj as? [String: Any],
          let serialized = try? JSONSerialization.data(withJSONObject: dataDict, options: []),
          let jsonString = String(data: serialized, encoding: .utf8)
        {
          a2uiMessages.append(jsonString)
        } else if let dataArray = dataObj as? [[String: Any]] {
          for item in dataArray {
            if let serialized = try? JSONSerialization.data(withJSONObject: item, options: []),
              let jsonString = String(data: serialized, encoding: .utf8)
            {
              a2uiMessages.append(jsonString)
            }
          }
        }
      }
    }
  }
}

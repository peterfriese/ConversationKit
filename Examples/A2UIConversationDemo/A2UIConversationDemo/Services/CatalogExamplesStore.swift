//
//  CatalogExamplesStore.swift
//  A2UIConversationDemo
//
//  Loads bundled A2UI v1.0 & v0.9.1 Basic Catalog specification examples
//  and rebindable surface message streams for instant or fallback rendering.
//

import Foundation

/// A bundled A2UI specification example (`examples/v1_0/*.json` or `examples/v0_9_1/*.json`).
public struct BundledA2UIExample: Identifiable, Hashable, Sendable {
  public let id: String
  public let slug: String
  public let title: String
  public let summary: String
  public let rawMessages: [String]
}

public enum CatalogExamplesStore: Sendable {
  /// Loads all bundled v1.0 Basic Catalog examples from the app bundle.
  public static func loadV10Examples(in bundleURL: URL = Bundle.main.bundleURL) -> [BundledA2UIExample] {
    let candidates = [
      bundleURL.appendingPathComponent("examples/v1_0/examples"),
      bundleURL.appendingPathComponent("examples/v1_0"),
      bundleURL.appendingPathComponent("Contents/Resources/examples/v1_0/examples"),
    ]

    for directoryURL in candidates {
      var isDir: ObjCBool = false
      if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir), isDir.boolValue {
        let loaded = loadExamples(from: directoryURL)
        if !loaded.isEmpty {
          return loaded
        }
      }
    }
    return []
  }

  /// Finds a specific bundled v1.0 example whose filename or slug matches `query`,
  /// rewriting its `surfaceId` to `targetSurfaceID` so each chat turn owns a distinct surface instance.
  public static func messagesForExample(
    matching query: String,
    targetSurfaceID: String,
    in examples: [BundledA2UIExample]
  ) -> (example: BundledA2UIExample, messages: [String])? {
    let lower = query.lowercased()
    guard
      let match = examples.first(where: {
        $0.slug.lowercased().contains(lower) || $0.title.lowercased().contains(lower)
      })
    else {
      return nil
    }
    let rewritten = rewriteSurfaceID(in: match.rawMessages, to: targetSurfaceID)
    return (match, rewritten)
  }

  /// Rewrites the first discovered `surfaceId` across a sequence of raw A2UI JSON messages
  /// to `newSurfaceID` so multiple turns in the same conversation timeline never overwrite each other.
  public static func rewriteSurfaceID(in rawMessages: [String], to newSurfaceID: String) -> [String] {
    var originalSurfaceID: String?
    for line in rawMessages {
      if let data = line.data(using: .utf8),
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      {
        for key in ["createSurface", "updateComponents", "updateDataModel", "beginRendering", "surfaceUpdate", "dataModelUpdate"] {
          if let inner = obj[key] as? [String: Any],
            let sid = inner["surfaceId"] as? String
          {
            originalSurfaceID = sid
            break
          }
        }
      }
      if originalSurfaceID != nil { break }
    }

    guard let originalSurfaceID, originalSurfaceID != newSurfaceID else {
      return rawMessages
    }

    return rawMessages.map {
      $0.replacingOccurrences(
        of: "\"surfaceId\":\"\(originalSurfaceID)\"",
        with: "\"surfaceId\":\"\(newSurfaceID)\""
      )
      .replacingOccurrences(
        of: "\"surfaceId\": \"\(originalSurfaceID)\"",
        with: "\"surfaceId\": \"\(newSurfaceID)\""
      )
    }
  }

  // MARK: - Private Helpers

  private static func loadExamples(from directoryURL: URL) -> [BundledA2UIExample] {
    guard
      let urls = try? FileManager.default.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: nil
      )
    else {
      return []
    }

    return urls
      .filter { $0.pathExtension.lowercased() == "json" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
      .compactMap { parseExample(at: $0) }
  }

  private static func parseExample(at url: URL) -> BundledA2UIExample? {
    guard
      let data = try? Data(contentsOf: url),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let messages = json["messages"] as? [Any]
    else {
      return nil
    }

    let slug = url.deletingPathExtension().lastPathComponent
    let fallbackTitle = slug
      .replacingOccurrences(of: "_", with: " ")
      .replacingOccurrences(of: "-", with: " ")
      .capitalized

    let title = (json["name"] as? String) ?? fallbackTitle
    let summary = (json["description"] as? String) ?? "Official A2UI v1.0 Basic Catalog example"

    let serializedMessages: [String] = messages.compactMap { msg in
      guard
        let msgData = try? JSONSerialization.data(withJSONObject: msg, options: []),
        let msgString = String(data: msgData, encoding: .utf8)
      else {
        return nil
      }
      return msgString
    }

    guard !serializedMessages.isEmpty else { return nil }

    return BundledA2UIExample(
      id: "v1_0-\(slug)",
      slug: slug,
      title: title,
      summary: summary,
      rawMessages: serializedMessages
    )
  }
}

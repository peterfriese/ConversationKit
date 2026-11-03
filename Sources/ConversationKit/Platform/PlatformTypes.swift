//
//  PlatformTypes.swift
//  ConversationKit
//
//  Clean-slate v2 Chameleon Cross-Platform Abstraction Layer (iOS 26+, macCatalyst 26+, macOS 26+).
//  Centralizes all UIKit / AppKit differences so Model/, Styles/, and Views/ remain 100% platform-agnostic.
//

import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

// MARK: - PlatformImageBox ($O(1)$ Diffing & Lazy Encoding)

/// A `Sendable`, `Hashable`, `Codable`, and `Identifiable` value wrapper around `PlatformImage`.
///
/// `PlatformImageBox` guarantees $O(1)$ equality and hashing via its stable `id: UUID`, preventing
/// expensive multi-megabyte bitmap comparisons during 120Hz SwiftUI view diffing.
/// Furthermore, PNG encoding is deferred lazily until `pngData()` or `encode(to:)` is explicitly called,
/// avoiding synchronous main-thread PNG compression when wrapping high-resolution photos.
///
/// - Note: Marked `@unchecked Sendable` because `id` is an immutable `UUID` and `image` is held as
///   an immutable reference (`let image: PlatformImage`) that is never mutated after initialization.
///   Avoids retroactive `extension PlatformImage: @unchecked Sendable` conformance warnings on iOS 26+.
public struct PlatformImageBox: @unchecked Sendable, Hashable, Codable, Identifiable {
  public let id: UUID
  public let image: PlatformImage
  private let cachedData: Data?

  /// Wraps a `PlatformImage` with a stable `UUID` without performing eager PNG encoding.
  public init(id: UUID = UUID(), _ image: PlatformImage) {
    self.id = id
    self.image = image
    self.cachedData = nil
  }

  /// Creates a `PlatformImageBox` by decoding encoded image data (PNG, JPEG, TIFF, HEIC).
  public init?(id: UUID = UUID(), data: Data) {
    guard let decoded = Self.decodeImage(from: data) else {
      return nil
    }
    self.id = id
    self.image = decoded
    self.cachedData = data
  }

  /// $O(1)$ equality check comparing only the stable `id`.
  public static func == (lhs: PlatformImageBox, rhs: PlatformImageBox) -> Bool {
    lhs.id == rhs.id
  }

  /// $O(1)$ hashing using only the stable `id`.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  /// Returns a SwiftUI `Image` representation of the underlying `PlatformImage`.
  public var swiftUIImage: Image {
    #if canImport(UIKit)
    Image(uiImage: image)
    #elseif canImport(AppKit)
    Image(nsImage: image)
    #endif
  }

  /// Pixel dimensions of the underlying image.
  public var pixelSize: CGSize {
    #if canImport(UIKit)
    if let cgImage = image.cgImage {
      return CGSize(width: cgImage.width, height: cgImage.height)
    }
    return CGSize(
      width: image.size.width * image.scale,
      height: image.size.height * image.scale
    )
    #elseif canImport(AppKit)
    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
      return CGSize(width: cgImage.width, height: cgImage.height)
    }
    return image.size
    #endif
  }

  /// Creates a solid-color image of the requested size (useful for placeholders and unit tests).
  public static func solidColor(
    red: CGFloat = 0.2,
    green: CGFloat = 0.5,
    blue: CGFloat = 0.9,
    alpha: CGFloat = 1.0,
    size: CGSize = CGSize(width: 64, height: 64)
  ) -> PlatformImageBox? {
    let width = max(1, Int(size.width.rounded()))
    let height = max(1, Int(size.height.rounded()))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      )
    else {
      return nil
    }
    context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    guard let cgImage = context.makeImage() else { return nil }
    return PlatformImageBox(Self.makePlatformImage(from: cgImage, scale: 1.0))
  }

  /// Lazily encodes the underlying `PlatformImage` into PNG data on demand.
  public func pngData() -> Data? {
    if let cachedData {
      return cachedData
    }
    #if canImport(UIKit)
    if let data = image.pngData() {
      return data
    }
    if let cgImage = image.cgImage {
      return Self.encodePNG(from: cgImage)
    }
    return nil
    #elseif canImport(AppKit)
    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
      return Self.encodePNG(from: cgImage)
    }
    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData)
    else {
      return nil
    }
    return bitmap.representation(using: .png, properties: [:])
    #endif
  }

  // MARK: Codable

  private enum CodingKeys: String, CodingKey {
    case id
    case imageData
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    let data = try container.decode(Data.self, forKey: .imageData)
    guard let decoded = Self.decodeImage(from: data) else {
      throw DecodingError.dataCorruptedError(
        forKey: .imageData,
        in: container,
        debugDescription: "Unable to decode PlatformImage from encoded imageData."
      )
    }
    self.id = id
    self.image = decoded
    self.cachedData = data
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    guard let data = pngData() else {
      throw EncodingError.invalidValue(
        self,
        EncodingError.Context(
          codingPath: encoder.codingPath,
          debugDescription: "Unable to encode PlatformImage to PNG data."
        )
      )
    }
    try container.encode(data, forKey: .imageData)
  }

  // MARK: Internal CGImage Helpers

  internal static func makePlatformImage(from cgImage: CGImage, scale: CGFloat = 2.0) -> PlatformImage {
    #if canImport(UIKit)
    return UIImage(cgImage: cgImage, scale: max(1.0, scale), orientation: .up)
    #elseif canImport(AppKit)
    let divisor = max(1.0, scale)
    let pointSize = NSSize(
      width: CGFloat(cgImage.width) / divisor,
      height: CGFloat(cgImage.height) / divisor
    )
    return NSImage(cgImage: cgImage, size: pointSize)
    #endif
  }

  internal static func decodeImage(from data: Data) -> PlatformImage? {
    let options: [CFString: Any] = [kCGImageSourceShouldCache: true]
    if let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
    {
      return makePlatformImage(from: cgImage, scale: 1.0)
    }
    #if canImport(UIKit)
    return UIImage(data: data)
    #elseif canImport(AppKit)
    return NSImage(data: data)
    #endif
  }

  internal static func encodePNG(from cgImage: CGImage) -> Data? {
    let mutableData = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        mutableData,
        UTType.png.identifier as CFString,
        1,
        nil
      )
    else {
      return nil
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }
    return mutableData as Data
  }
}

// MARK: - PlatformThumbnailError

/// Errors thrown by `PlatformThumbnailGenerator` during thumbnail generation or QuickLook URL resolution.
public enum PlatformThumbnailError: Error, Sendable, Equatable, LocalizedError {
  case thumbnailGenerationFailed
  case missingAttachmentData
  case quickLookWriteFailed(String)
  case pathTraversalRejected

  public var errorDescription: String? {
    switch self {
    case .thumbnailGenerationFailed:
      return "Failed to generate a downsampled thumbnail for the attachment."
    case .missingAttachmentData:
      return "No data was available to materialize the QuickLook preview file."
    case .quickLookWriteFailed(let reason):
      return "Failed to write temporary QuickLook preview file: \(reason)"
    case .pathTraversalRejected:
      return "Rejected unsafe QuickLook file path outside the sandboxed directory."
    }
  }
}

// MARK: - PlatformThumbnailGenerator (Actor)

/// Generates memory-safe, downsampled thumbnails (`ImageIO` / `PDFKit` / `QLThumbnailGenerator`)
/// and manages sanitized QuickLook preview files strictly off `@MainActor`.
///
/// Maintains a bounded in-memory LRU cache (up to 128 entries) keyed by `(attachmentID, maxPixelSize)`
/// so scrolling timeline cells hit cached `PlatformImageBox` thumbnails in $O(1)$ without re-decoding.
public actor PlatformThumbnailGenerator {
  public static let shared = PlatformThumbnailGenerator()

  public static let defaultMaxPixelSize: Int = 320
  public static let maxCacheEntries: Int = 128

  private struct CacheKey: Hashable, Sendable {
    let attachmentID: String
    let maxPixelSize: Int
  }

  private let capacity: Int
  private var cache: [CacheKey: PlatformImageBox] = [:]
  private var accessOrder: [CacheKey] = []
  private var inFlight: [CacheKey: Task<PlatformImageBox, any Error>] = [:]

  public init(capacity: Int = PlatformThumbnailGenerator.maxCacheEntries) {
    self.capacity = max(1, capacity)
  }

  /// Returns a cached thumbnail in $O(1)$ if already generated for `(attachmentID, maxPixelSize)`.
  public func cachedThumbnail(
    for id: String,
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize
  ) -> PlatformImageBox? {
    let key = CacheKey(attachmentID: id, maxPixelSize: max(16, maxPixelSize))
    guard let hit = cache[key] else { return nil }
    touchKey(key)
    return hit
  }

  // MARK: Data-Backed Thumbnailing

  /// Generates a memory-safe downsampled thumbnail from raw `Data` off the main actor.
  public func thumbnail(
    id: String,
    data: Data,
    contentType: UTType? = nil,
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize,
    scale: CGFloat = 2.0
  ) async throws -> PlatformImageBox {
    let clampedSize = max(16, maxPixelSize)
    let key = CacheKey(attachmentID: id, maxPixelSize: clampedSize)

    if let cached = cache[key] {
      touchKey(key)
      return cached
    }
    if let existingTask = inFlight[key] {
      return try await existingTask.value
    }

    let task = Task<PlatformImageBox, any Error> {
      try Task.checkCancellation()
      if contentType?.conforms(to: .pdf) == true,
        let pdfBox = Self.downsamplePDFData(data, maxPixelSize: clampedSize, scale: scale)
      {
        return pdfBox
      }
      if let imageBox = Self.downsampleImageData(data, maxPixelSize: clampedSize, scale: scale) {
        return imageBox
      }
      if let pdfBox = Self.downsamplePDFData(data, maxPixelSize: clampedSize, scale: scale) {
        return pdfBox
      }
      throw PlatformThumbnailError.thumbnailGenerationFailed
    }

    inFlight[key] = task
    do {
      let box = try await task.value
      inFlight[key] = nil
      storeInCache(box, for: key)
      return box
    } catch {
      inFlight[key] = nil
      throw error
    }
  }

  // MARK: URL-Backed Thumbnailing

  /// Generates a memory-safe downsampled thumbnail from a local file `URL` off the main actor.
  /// Automatically manages security-scoped resource access when applicable.
  public func thumbnail(
    id: String,
    fileURL: URL,
    contentType: UTType? = nil,
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize,
    scale: CGFloat = 2.0
  ) async throws -> PlatformImageBox {
    let clampedSize = max(16, maxPixelSize)
    let key = CacheKey(attachmentID: id, maxPixelSize: clampedSize)

    if let cached = cache[key] {
      touchKey(key)
      return cached
    }
    if let existingTask = inFlight[key] {
      return try await existingTask.value
    }

    let task = Task<PlatformImageBox, any Error> {
      try Task.checkCancellation()
      let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
      defer {
        if didStartAccessing {
          fileURL.stopAccessingSecurityScopedResource()
        }
      }

      let resolvedType = contentType ?? UTType(filenameExtension: fileURL.pathExtension)

      if resolvedType?.conforms(to: .pdf) == true || fileURL.pathExtension.lowercased() == "pdf" {
        if let pdfBox = Self.downsamplePDFFile(at: fileURL, maxPixelSize: clampedSize, scale: scale) {
          return pdfBox
        }
      }

      if let imageBox = Self.downsampleImageFile(at: fileURL, maxPixelSize: clampedSize, scale: scale) {
        return imageBox
      }

      if let pdfBox = Self.downsamplePDFFile(at: fileURL, maxPixelSize: clampedSize, scale: scale) {
        return pdfBox
      }

      try Task.checkCancellation()
      if let qlBox = try? await Self.generateQuickLookThumbnail(
        for: fileURL,
        maxPixelSize: clampedSize,
        scale: scale
      ) {
        return qlBox
      }

      throw PlatformThumbnailError.thumbnailGenerationFailed
    }

    inFlight[key] = task
    do {
      let box = try await task.value
      inFlight[key] = nil
      storeInCache(box, for: key)
      return box
    } catch {
      inFlight[key] = nil
      throw error
    }
  }

  // MARK: PlatformImageBox Downsampling

  /// Generates a memory-safe downsampled thumbnail from an in-memory `PlatformImageBox`.
  public func thumbnail(
    id: String,
    imageBox: PlatformImageBox,
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize,
    scale: CGFloat = 2.0
  ) async throws -> PlatformImageBox {
    let clampedSize = max(16, maxPixelSize)
    let key = CacheKey(attachmentID: id, maxPixelSize: clampedSize)

    if let cached = cache[key] {
      touchKey(key)
      return cached
    }
    if let existingTask = inFlight[key] {
      return try await existingTask.value
    }

    let task = Task<PlatformImageBox, any Error> {
      try Task.checkCancellation()
      let currentPixelSize = imageBox.pixelSize
      if max(currentPixelSize.width, currentPixelSize.height) <= CGFloat(clampedSize) {
        return imageBox
      }
      if let data = imageBox.pngData(),
        let downsampled = Self.downsampleImageData(data, maxPixelSize: clampedSize, scale: scale)
      {
        return downsampled
      }
      return imageBox
    }

    inFlight[key] = task
    do {
      let box = try await task.value
      inFlight[key] = nil
      storeInCache(box, for: key)
      return box
    } catch {
      inFlight[key] = nil
      throw error
    }
  }

  // MARK: QuickLook Temporary File Resolution & Sanitization (`MUST-FIX-2`)

  /// Base temporary directory used for materialized QuickLook preview files.
  public nonisolated static var quickLookDirectoryURL: URL {
    FileManager.default.temporaryDirectory
      .appending(path: "ConversationKitQuickLook", directoryHint: .isDirectory)
  }

  /// Sanitizes an untrusted filename by extracting its `lastPathComponent` and stripping
  /// path separators (`/`, `\`, `:`), parent traversal sequences (`..`), and control characters.
  public nonisolated static func sanitizeFilename(_ rawFilename: String) -> String {
    let normalizedSeparators = rawFilename.replacingOccurrences(of: "\\", with: "/")
    let baseComponent = (normalizedSeparators as NSString).lastPathComponent

    let forbiddenCharacters = CharacterSet.controlCharacters
      .union(.illegalCharacters)
      .union(CharacterSet(charactersIn: "/\\:\0"))

    let filteredScalars = baseComponent.unicodeScalars.filter { scalar in
      !forbiddenCharacters.contains(scalar)
    }
    var cleaned = String(String.UnicodeScalarView(filteredScalars))
      .trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespacesAndNewlines))
      .replacingOccurrences(of: "..", with: "_")
      .trimmingCharacters(in: CharacterSet(charactersIn: ". _").union(.whitespacesAndNewlines))

    if cleaned.isEmpty {
      cleaned = "attachment.bin"
    }
    if cleaned.count > 120 {
      let ext = (cleaned as NSString).pathExtension
      let stem = (cleaned as NSString).deletingPathExtension
      let prefix = String(stem.prefix(96))
      cleaned = ext.isEmpty ? prefix : "\(prefix).\(ext)"
    }
    return cleaned
  }

  /// Resolves a local `URL` suitable for SwiftUI's `.quickLookPreview(_:)` off the main actor.
  ///
  /// Sanitizes `filename` (`lastPathComponent`, strips `/`, `\`, `:`, `..`, control chars),
  /// prefixes with `idString`, writes atomically into
  /// `FileManager.default.temporaryDirectory.appending(path: "ConversationKitQuickLook")`,
  /// and strictly verifies `resolvedURL.standardizedFileURL.path.hasPrefix(quickLookDir.standardizedFileURL.path)`
  /// to prevent path traversal (`MUST-FIX-2`).
  public func resolveQuickLookURL(
    idString: String,
    filename: String,
    dataProvider: @Sendable () -> Data?
  ) throws -> URL {
    try Task.checkCancellation()
    let fileManager = FileManager.default
    let quickLookDir = Self.quickLookDirectoryURL.standardizedFileURL

    try fileManager.createDirectory(at: quickLookDir, withIntermediateDirectories: true)

    let safeIDPrefix = Self.sanitizeIdentifierPrefix(idString)
    let safeFilename = Self.sanitizeFilename(filename)
    let combinedName = "\(safeIDPrefix)-\(safeFilename)"

    let resolvedURL = quickLookDir
      .appending(path: combinedName, directoryHint: .notDirectory)
      .standardizedFileURL

    let basePathWithSlash = quickLookDir.path.hasSuffix("/")
      ? quickLookDir.path
      : quickLookDir.path + "/"

    guard resolvedURL.path.hasPrefix(basePathWithSlash) else {
      throw PlatformThumbnailError.pathTraversalRejected
    }

    if fileManager.fileExists(atPath: resolvedURL.path) {
      return resolvedURL
    }

    guard let data = dataProvider() else {
      throw PlatformThumbnailError.missingAttachmentData
    }

    do {
      try data.write(to: resolvedURL, options: [.atomic])
      return resolvedURL
    } catch {
      throw PlatformThumbnailError.quickLookWriteFailed(error.localizedDescription)
    }
  }

  // MARK: Private Cache Management

  private func touchKey(_ key: CacheKey) {
    if let index = accessOrder.firstIndex(of: key) {
      accessOrder.remove(at: index)
    }
    accessOrder.append(key)
  }

  private func storeInCache(_ box: PlatformImageBox, for key: CacheKey) {
    cache[key] = box
    touchKey(key)
    while accessOrder.count > capacity {
      let oldest = accessOrder.removeFirst()
      cache.removeValue(forKey: oldest)
    }
  }

  private nonisolated static func sanitizeIdentifierPrefix(_ rawID: String) -> String {
    if let uuid = UUID(uuidString: rawID) {
      return uuid.uuidString
    }
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let scalars = rawID.unicodeScalars.filter { allowed.contains($0) }
    let sanitized = String(String.UnicodeScalarView(scalars)).prefix(64)
    return sanitized.isEmpty ? UUID().uuidString : String(sanitized)
  }

  // MARK: Private ImageIO / PDFKit / QuickLook Downsamplers

  private nonisolated static func thumbnailOptions(maxPixelSize: Int) -> CFDictionary {
    [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: max(16, maxPixelSize)
    ] as CFDictionary
  }

  private nonisolated static func downsampleImageData(
    _ data: Data,
    maxPixelSize: Int,
    scale: CGFloat
  ) -> PlatformImageBox? {
    let sourceOptions: CFDictionary = [kCGImageSourceShouldCache: false] as CFDictionary
    guard
      let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
      let cgImage = CGImageSourceCreateThumbnailAtIndex(
        source,
        0,
        thumbnailOptions(maxPixelSize: maxPixelSize)
      )
    else {
      return nil
    }
    let platformImage = PlatformImageBox.makePlatformImage(from: cgImage, scale: scale)
    return PlatformImageBox(platformImage)
  }

  private nonisolated static func downsampleImageFile(
    at url: URL,
    maxPixelSize: Int,
    scale: CGFloat
  ) -> PlatformImageBox? {
    let sourceOptions: CFDictionary = [kCGImageSourceShouldCache: false] as CFDictionary
    guard
      let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions),
      let cgImage = CGImageSourceCreateThumbnailAtIndex(
        source,
        0,
        thumbnailOptions(maxPixelSize: maxPixelSize)
      )
    else {
      return nil
    }
    let platformImage = PlatformImageBox.makePlatformImage(from: cgImage, scale: scale)
    return PlatformImageBox(platformImage)
  }

  private nonisolated static func downsamplePDFData(
    _ data: Data,
    maxPixelSize: Int,
    scale: CGFloat
  ) -> PlatformImageBox? {
    guard let document = PDFDocument(data: data) else { return nil }
    return renderFirstPDFPage(of: document, maxPixelSize: maxPixelSize, scale: scale)
  }

  private nonisolated static func downsamplePDFFile(
    at url: URL,
    maxPixelSize: Int,
    scale: CGFloat
  ) -> PlatformImageBox? {
    guard let document = PDFDocument(url: url) else { return nil }
    return renderFirstPDFPage(of: document, maxPixelSize: maxPixelSize, scale: scale)
  }

  private nonisolated static func renderFirstPDFPage(
    of document: PDFDocument,
    maxPixelSize: Int,
    scale: CGFloat
  ) -> PlatformImageBox? {
    guard let page = document.page(at: 0) else { return nil }
    let pageRect = page.bounds(for: .mediaBox)
    guard pageRect.width > 0, pageRect.height > 0 else { return nil }

    let maxDimension = max(pageRect.width, pageRect.height)
    let ratio = CGFloat(max(16, maxPixelSize)) / maxDimension
    let targetWidth = max(1, Int((pageRect.width * ratio).rounded()))
    let targetHeight = max(1, Int((pageRect.height * ratio).rounded()))

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard
      let context = CGContext(
        data: nil,
        width: targetWidth,
        height: targetHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      )
    else {
      return nil
    }

    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
    context.saveGState()
    context.scaleBy(x: ratio, y: ratio)
    page.draw(with: .mediaBox, to: context)
    context.restoreGState()

    guard let cgImage = context.makeImage() else { return nil }
    return PlatformImageBox(PlatformImageBox.makePlatformImage(from: cgImage, scale: scale))
  }

  private nonisolated static func generateQuickLookThumbnail(
    for url: URL,
    maxPixelSize: Int,
    scale: CGFloat
  ) async throws -> PlatformImageBox {
    let pointDimension = CGFloat(max(16, maxPixelSize)) / max(1.0, scale)
    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: CGSize(width: pointDimension, height: pointDimension),
      scale: max(1.0, scale),
      representationTypes: .thumbnail
    )
    let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    let cgImage = representation.cgImage
    let image = PlatformImageBox.makePlatformImage(from: cgImage, scale: scale)
    return PlatformImageBox(image)
  }
}

// MARK: - PlatformPasteboard

/// Cross-platform pasteboard abstraction for copying text/code and reading pasted images or files.
public enum PlatformPasteboard: Sendable {
  /// Copies plain text to the system general pasteboard.
  @MainActor
  public static func copyText(_ text: String) {
    #if canImport(UIKit)
    UIPasteboard.general.string = text
    #elseif canImport(AppKit)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    #endif
  }

  /// Reads plain text from the system general pasteboard, if present.
  @MainActor
  public static func readText() -> String? {
    #if canImport(UIKit)
    return UIPasteboard.general.string
    #elseif canImport(AppKit)
    return NSPasteboard.general.string(forType: .string)
    #endif
  }

  /// Lightweight pasteboard metadata check indicating whether pasted images or file attachments
  /// are available without synchronously decoding image or file `Data` blobs on the main thread (`F-09`).
  @MainActor
  public static var hasAttachments: Bool {
    #if canImport(UIKit)
    let pasteboard = UIPasteboard.general
    return pasteboard.hasImages
      || pasteboard.hasURLs
      || pasteboard.contains(pasteboardTypes: [
        UTType.png.identifier,
        UTType.jpeg.identifier,
        UTType.pdf.identifier,
        UTType.image.identifier,
      ])
    #elseif canImport(AppKit)
    let pasteboard = NSPasteboard.general
    if pasteboard.canReadObject(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]
    ) {
      return true
    }
    let supportedTypes: [NSPasteboard.PasteboardType] = [.png, .pdf, .tiff, .fileURL]
    return pasteboard.availableType(from: supportedTypes) != nil
    #endif
  }

  /// Reads pasted images or file payloads from the system pasteboard for composer insertion.
  @MainActor
  public static func readAttachments() -> [(data: Data, contentType: UTType, filename: String)] {
    var results: [(data: Data, contentType: UTType, filename: String)] = []

    #if canImport(UIKit)
    let pasteboard = UIPasteboard.general
    for (index, item) in pasteboard.items.enumerated() {
      if let pngData = Self.extractData(from: item[UTType.png.identifier]) {
        results.append((data: pngData, contentType: .png, filename: "Pasted-Image-\(index + 1).png"))
      } else if let jpegData = Self.extractData(from: item[UTType.jpeg.identifier]) {
        results.append((data: jpegData, contentType: .jpeg, filename: "Pasted-Image-\(index + 1).jpg"))
      } else if let pdfData = Self.extractData(from: item[UTType.pdf.identifier]) {
        results.append((data: pdfData, contentType: .pdf, filename: "Pasted-Document-\(index + 1).pdf"))
      } else if let image = item[UTType.image.identifier] as? UIImage,
        let data = image.pngData()
      {
        results.append((data: data, contentType: .png, filename: "Pasted-Image-\(index + 1).png"))
      }
    }

    if results.isEmpty, let image = pasteboard.image, let data = image.pngData() {
      results.append((data: data, contentType: .png, filename: "Pasted-Image.png"))
    }
    #elseif canImport(AppKit)
    let pasteboard = NSPasteboard.general
    if let urls = pasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]
    ) as? [URL] {
      for url in urls {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
          if didStart {
            url.stopAccessingSecurityScopedResource()
          }
        }
        if let data = try? Data(contentsOf: url) {
          let contentType = UTType(filenameExtension: url.pathExtension) ?? .data
          let name = PlatformThumbnailGenerator.sanitizeFilename(url.lastPathComponent)
          results.append((data: data, contentType: contentType, filename: name))
        }
      }
    }

    if results.isEmpty, let items = pasteboard.pasteboardItems {
      for (index, item) in items.enumerated() {
        if let pngData = item.data(forType: .png) {
          results.append((data: pngData, contentType: .png, filename: "Pasted-Image-\(index + 1).png"))
        } else if let pdfData = item.data(forType: .pdf) {
          results.append((data: pdfData, contentType: .pdf, filename: "Pasted-Document-\(index + 1).pdf"))
        } else if let tiffData = item.data(forType: .tiff),
          let imageBox = PlatformImageBox(data: tiffData),
          let pngData = imageBox.pngData()
        {
          results.append((data: pngData, contentType: .png, filename: "Pasted-Image-\(index + 1).png"))
        }
      }
    }
    #endif

    return results
  }

  #if canImport(UIKit)
  private static func extractData(from rawValue: Any?) -> Data? {
    if let data = rawValue as? Data {
      return data
    }
    if let image = rawValue as? UIImage {
      return image.pngData()
    }
    return nil
  }
  #endif
}

// MARK: - StreamingHapticsConfiguration

/// Configures adaptive haptic feedback during assistant response streaming and agentic lifecycle transitions.
///
/// `StreamingHapticsConfiguration` models haptic cadence, coalescing interval, and base intensity
/// as a `Sendable`, `Hashable`, `Codable` value type suitable for SwiftUI environment propagation.
public struct StreamingHapticsConfiguration: Sendable, Hashable, Codable {
  /// The tactile cadence profile applied while an assistant response is streaming.
  public enum Cadence: String, Sendable, Hashable, Codable, CaseIterable {
    /// Disables all streaming haptics (silent streaming).
    case off
    /// Subtle, tactile taps throttled to ~55ms while tokens reveal, plus milestone and completion taps.
    case subtle
    /// Distinct, physical ChatGPT-style Taptic thumps (~65ms interval, `.medium` generator with `.rigid` boundary accents).
    case punchy
    /// Sharp, mechanical `.rigid` key-click ticks (~48ms minimum interval).
    case typewriter
    /// Only triggers haptics on lifecycle milestones (first token arrival, thinking/tool completion, block commit, stream completion).
    case milestonesOnly
  }

  /// The active streaming haptic cadence.
  public var cadence: Cadence

  /// Minimum time interval (in seconds) between consecutive streaming token ticks, clamped to `>= 0.015`.
  public var minimumInterval: TimeInterval {
    didSet {
      if minimumInterval < 0.015 {
        minimumInterval = 0.015
      }
    }
  }

  /// Base haptic impact intensity in the normalized range `0.0...1.0`.
  public var intensity: Double {
    didSet {
      intensity = min(1.0, max(0.0, intensity))
    }
  }

  /// Creates a streaming haptics configuration.
  ///
  /// - Parameters:
  ///   - cadence: The haptic cadence profile (defaults to `.punchy`).
  ///   - minimumInterval: Minimum coalescing interval in seconds between token ticks (clamped to `>= 0.015`, defaults to `0.065`).
  ///   - intensity: Base impact intensity in `0.0...1.0` (clamped to `0.0...1.0`, defaults to `0.82`).
  public init(
    cadence: Cadence = .punchy,
    minimumInterval: TimeInterval = 0.065,
    intensity: Double = 0.82
  ) {
    self.cadence = cadence
    self.minimumInterval = max(0.015, minimumInterval)
    self.intensity = min(1.0, max(0.0, intensity))
  }

  private enum CodingKeys: String, CodingKey {
    case cadence
    case minimumInterval
    case intensity
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let cadence = try container.decode(Cadence.self, forKey: .cadence)
    let minimumInterval = try container.decode(TimeInterval.self, forKey: .minimumInterval)
    let intensity = try container.decode(Double.self, forKey: .intensity)
    self.init(cadence: cadence, minimumInterval: minimumInterval, intensity: intensity)
  }

  // MARK: Presets

  /// Disables all streaming haptics.
  public static let disabled = StreamingHapticsConfiguration(
    cadence: .off,
    minimumInterval: 0.055,
    intensity: 0.0
  )

  /// Subtle streaming haptics (~55ms coalescing, 0.62 intensity).
  public static let subtle = StreamingHapticsConfiguration(
    cadence: .subtle,
    minimumInterval: 0.055,
    intensity: 0.62
  )

  /// Default punchy ChatGPT-style streaming haptics (~65ms coalescing, 0.82 intensity with rigid boundary accents).
  public static let punchy = StreamingHapticsConfiguration(
    cadence: .punchy,
    minimumInterval: 0.065,
    intensity: 0.82
  )

  /// Sharp, mechanical typewriter streaming haptics (~48ms coalescing, 0.75 intensity with rigid key-click accents).
  public static let typewriter = StreamingHapticsConfiguration(
    cadence: .typewriter,
    minimumInterval: 0.048,
    intensity: 0.75
  )

  /// Milestone-only haptics on key agentic/streaming transitions without per-token ticks.
  public static let milestonesOnly = StreamingHapticsConfiguration(
    cadence: .milestonesOnly,
    minimumInterval: 0.055,
    intensity: 0.80
  )

  // MARK: Computed Helpers

  /// Whether streaming haptics are active.
  public var isEnabled: Bool {
    cadence != .off
  }

  /// Whether incremental token reveal ticks should fire.
  public var triggersTokenTicks: Bool {
    cadence == .subtle || cadence == .punchy || cadence == .typewriter
  }

  /// Whether lifecycle milestone and completion haptics should fire.
  public var triggersMilestones: Bool {
    cadence != .off
  }
}

// MARK: - PlatformHapticEvent & Haptic Triggers

/// Semantic haptic feedback events used across `ConversationKit`.
public enum PlatformHapticEvent: Sendable, Hashable {
  case send
  case selection
  case copySuccess
  case warning
  case error
  case streamingTick(intensity: Double)
  case streamingMilestone
  case streamingComplete

  // Aliases matching ADR §3.2.1 & §3.5.2 terminology
  public static let tokenInserted: PlatformHapticEvent = .selection
  public static let tokenRemoved: PlatformHapticEvent = .selection

  /// Default streaming tick event (`intensity: 0.82`).
  public static let streamingTick: PlatformHapticEvent = .streamingTick(intensity: 0.82)
}

/// Namespace providing cross-platform haptic feedback triggers and coalesced streaming haptics.
public enum PlatformHaptics: Sendable {
  #if canImport(UIKit) && !os(visionOS)
  @MainActor private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
  @MainActor private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
  @MainActor private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
  @MainActor private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
  @MainActor private static let selectionGenerator = UISelectionFeedbackGenerator()
  @MainActor private static let notificationGenerator = UINotificationFeedbackGenerator()
  #endif

  @MainActor private static var lastStreamingTickTime: TimeInterval = -.infinity

  /// Number of coalesced streaming token ticks triggered since the last reset (for deterministic testing).
  @MainActor public private(set) static var streamingTickCountForTesting: Int = 0

  /// Number of streaming milestone/completion haptics triggered since the last reset (for deterministic testing).
  @MainActor public private(set) static var streamingMilestoneCountForTesting: Int = 0

  /// Resets the streaming haptic coalescing timestamp and testing counters.
  @MainActor
  public static func resetStreamingCountersForTesting() {
    lastStreamingTickTime = -.infinity
    streamingTickCountForTesting = 0
    streamingMilestoneCountForTesting = 0
  }

  /// Warms up the underlying Taptic Engine generators ahead of an incoming assistant stream.
  @MainActor
  public static func prepareStreamingHaptics(
    configuration: StreamingHapticsConfiguration = .punchy
  ) {
    guard configuration.isEnabled else { return }
    #if canImport(UIKit) && !os(visionOS)
    lightGenerator.prepare()
    mediumGenerator.prepare()
    rigidGenerator.prepare()
    #endif
  }

  /// Triggers a coalesced streaming token tick according to `configuration`.
  ///
  /// - Parameters:
  ///   - configuration: The active `StreamingHapticsConfiguration`.
  ///   - isPunctuationOrBoundary: Lazily evaluated autoclosure indicating whether the newly revealed text ends on a punctuation mark, clause boundary, or newline. Evaluated only after the coalescing gate passes.
  ///   - now: Monotonic timestamp in seconds (defaults to `ProcessInfo.processInfo.systemUptime`).
  /// - Returns: `true` if a tick was emitted, or `false` if disabled or throttled by the coalescing gate.
  @MainActor
  @discardableResult
  public static func triggerStreamingTick(
    configuration: StreamingHapticsConfiguration,
    isPunctuationOrBoundary: @autoclosure () -> Bool = false,
    now: TimeInterval = ProcessInfo.processInfo.systemUptime
  ) -> Bool {
    guard configuration.triggersTokenTicks else { return false }
    guard now - lastStreamingTickTime >= configuration.minimumInterval else { return false }

    let isBoundary = isPunctuationOrBoundary()
    lastStreamingTickTime = now
    streamingTickCountForTesting += 1

    #if canImport(UIKit) && !os(visionOS)
    switch configuration.cadence {
    case .punchy:
      let effectiveIntensity = min(
        1.0,
        max(0.0, configuration.intensity + (isBoundary ? 0.18 : 0.0))
      )
      if isBoundary {
        rigidGenerator.impactOccurred(intensity: CGFloat(effectiveIntensity))
      } else {
        mediumGenerator.impactOccurred(intensity: CGFloat(effectiveIntensity))
      }
    case .typewriter:
      let effectiveIntensity = min(
        1.0,
        max(0.0, configuration.intensity + (isBoundary ? 0.20 : 0.0))
      )
      rigidGenerator.impactOccurred(intensity: CGFloat(effectiveIntensity))
    case .subtle:
      let effectiveIntensity = min(
        1.0,
        max(0.0, configuration.intensity + (isBoundary ? 0.18 : 0.0))
      )
      if isBoundary {
        mediumGenerator.impactOccurred(intensity: CGFloat(effectiveIntensity))
      } else {
        lightGenerator.impactOccurred(intensity: CGFloat(effectiveIntensity))
      }
    case .off, .milestonesOnly:
      break
    }
    #elseif canImport(AppKit)
    // Keep macOS trackpads silent during high-frequency token reveal ticks.
    _ = isBoundary
    #endif

    return true
  }

  /// Triggers a streaming lifecycle milestone haptic (such as first token arrival, block commit, or stream completion).
  ///
  /// - Parameters:
  ///   - configuration: The active `StreamingHapticsConfiguration`.
  ///   - isCompletion: Whether this milestone marks the completion of the assistant stream.
  /// - Returns: `true` if the milestone haptic was emitted, or `false` if haptics are disabled.
  @MainActor
  @discardableResult
  public static func triggerStreamingMilestone(
    configuration: StreamingHapticsConfiguration,
    isCompletion: Bool = false
  ) -> Bool {
    guard configuration.triggersMilestones else { return false }
    streamingMilestoneCountForTesting += 1
    triggerHaptic(isCompletion ? .streamingComplete : .streamingMilestone)
    return true
  }

  @MainActor
  public static func triggerHaptic(_ event: PlatformHapticEvent) {
    #if canImport(UIKit) && !os(visionOS)
    switch event {
    case .send:
      rigidGenerator.impactOccurred(intensity: 0.85)
    case .selection:
      selectionGenerator.selectionChanged()
    case .copySuccess:
      notificationGenerator.notificationOccurred(.success)
    case .warning:
      notificationGenerator.notificationOccurred(.warning)
    case .error:
      notificationGenerator.notificationOccurred(.error)
    case .streamingTick(let intensity):
      let clamped = min(1.0, max(0.0, intensity))
      mediumGenerator.impactOccurred(intensity: CGFloat(clamped))
    case .streamingMilestone:
      rigidGenerator.impactOccurred(intensity: 0.85)
    case .streamingComplete:
      mediumGenerator.impactOccurred(intensity: 0.90)
    }
    #elseif canImport(AppKit)
    switch event {
    case .send, .copySuccess, .streamingComplete:
      NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    case .selection, .streamingMilestone:
      NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    case .warning, .error:
      NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    case .streamingTick:
      break
    }
    #endif
  }
}

extension PlatformHapticEvent {
  /// Triggers this haptic event on the main actor.
  @MainActor
  public static func triggerHaptic(_ event: PlatformHapticEvent) {
    PlatformHaptics.triggerHaptic(event)
  }
}

// MARK: - Cross-Platform Semantic Colors

extension Color {
  /// Adaptive primary surface background across iOS and macOS.
  public static var platformBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .systemBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .windowBackgroundColor)
    #endif
  }

  /// Adaptive secondary surface background across iOS and macOS.
  public static var platformSecondaryBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .secondarySystemBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .controlBackgroundColor)
    #endif
  }

  /// Adaptive tertiary surface background across iOS and macOS.
  public static var platformTertiaryBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .underPageBackgroundColor)
    #endif
  }

  /// Adaptive hairline separator color across iOS and macOS.
  public static var platformSeparator: Color {
    #if canImport(UIKit)
    Color(uiColor: .separator)
    #elseif canImport(AppKit)
    Color(nsColor: .separatorColor)
    #endif
  }

  /// Semantic tinted fill for right-aligned user message bubbles (never uses Liquid Glass in scroll cells).
  public static var platformUserBubbleFill: Color {
    Color.accentColor.opacity(0.14)
  }

  /// Semantic header bar background for fenced code blocks in `StreamingMarkdownView`.
  public static var platformCodeBlockHeaderBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .tertiarySystemFill)
    #elseif canImport(AppKit)
    Color(nsColor: .quaternaryLabelColor).opacity(0.35)
    #endif
  }

  /// Semantic body container background for fenced code blocks in `StreamingMarkdownView`.
  public static var platformCodeBlockBodyBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .secondarySystemBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .textBackgroundColor).opacity(0.65)
    #endif
  }
}

// MARK: - URL Security Allowlist (`MUST-FIX-3` / `AC-18`)

extension URL {
  /// Strictly validates that the URL uses an `"http"` or `"https"` scheme (case-insensitive)
  /// and has a non-empty host (`MUST-FIX-3`, `AC-18`).
  ///
  /// Rejects `javascript:`, `file:`, `data:`, `vbscript:`, and custom app URL schemes from untrusted LLM output.
  public var isAllowedConversationURL: Bool {
    guard
      let scheme = self.scheme?.lowercased(),
      scheme == "http" || scheme == "https",
      let host = self.host(),
      !host.isEmpty
    else {
      return false
    }
    return true
  }
}

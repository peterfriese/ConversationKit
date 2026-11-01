//
//  Attachment.swift
//  ConversationKit
//
//  Universal multimodal attachment model with O(1) identity diffing and off-main-actor thumbnailing.
//

import Foundation
import UniformTypeIdentifiers

/// A universal multimodal attachment representing an image, PDF, audio clip, video, source code file,
/// or arbitrary document in `ConversationKit`.
///
/// `ConversationAttachment` guarantees $O(1)$ equality and hashing (`[MF-4]`) by comparing metadata
/// and stable payload identifiers (`PlatformImageBox.id`, `URL`, or `Data.count`) without scanning
/// multi-megabyte byte buffers during 120Hz SwiftUI view diffing.
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Attach a local file URL or platform image
/// let fileAttachment = ConversationAttachment(fileURL: documentURL)
/// let photoAttachment = ConversationAttachment(image: photo, filename: "Receipt.jpg")
///
/// // Layer 2 (Stratosphere): Track determinate upload progress (0.0...1.0)
/// let uploadingAttachment = ConversationAttachment(
///   fileURL: largeArchiveURL,
///   uploadState: .uploading(progress: 0.45)
/// )
/// ```
public struct ConversationAttachment: Identifiable, Hashable, Sendable, Codable {

  // MARK: - Nested Types

  /// Storage representation for a `ConversationAttachment`.
  public enum Payload: Sendable, Hashable, Codable {
    /// An in-memory platform image wrapped in `PlatformImageBox` for $O(1)$ diffing.
    case image(PlatformImageBox)
    /// A local or security-scoped file `URL`.
    case file(URL)
    /// An in-memory `Data` payload with an explicit `UTType` and filename.
    case data(Data, contentType: UTType, filename: String)

    /// $O(1)$ equality comparison that avoids byte-comparing large `Data` buffers during view diffing.
    public static func == (lhs: Payload, rhs: Payload) -> Bool {
      switch (lhs, rhs) {
      case (.image(let lhsBox), .image(let rhsBox)):
        return lhsBox == rhsBox
      case (.file(let lhsURL), .file(let rhsURL)):
        return lhsURL == rhsURL
      case (
        .data(let lhsData, let lhsType, let lhsName),
        .data(let rhsData, let rhsType, let rhsName)
      ):
        guard lhsData.count == rhsData.count,
          lhsType == rhsType,
          lhsName == rhsName
        else {
          return false
        }
        guard let lhsFirst = lhsData.first, let rhsFirst = rhsData.first,
          let lhsLast = lhsData.last, let rhsLast = rhsData.last
        else {
          return true
        }
        return lhsFirst == rhsFirst && lhsLast == rhsLast
      default:
        return false
      }
    }

    /// $O(1)$ hashing using stable identifiers or byte counts rather than full buffer scans.
    public func hash(into hasher: inout Hasher) {
      switch self {
      case .image(let box):
        hasher.combine(0)
        hasher.combine(box)
      case .file(let url):
        hasher.combine(1)
        hasher.combine(url)
      case .data(let data, let contentType, let filename):
        hasher.combine(2)
        hasher.combine(data.count)
        hasher.combine(contentType)
        hasher.combine(filename)
      }
    }
  }

  /// Upload lifecycle state used by `AttachmentTrayView` to render determinate progress rings
  /// and gate message submission (`isReadyForSubmission`).
  public enum UploadState: Sendable, Hashable, Codable {
    /// The attachment has finished uploading or is locally ready for immediate submission.
    case ready
    /// The attachment is actively uploading with determinate progress in `0.0...1.0`.
    case uploading(progress: Double)
    /// The attachment upload failed with a user-presentable error description.
    case failed(error: String)
  }

  /// High-level semantic attachment category inferred from `UTType` and `Payload`.
  public enum Kind: String, Sendable, Hashable, Codable, CaseIterable {
    case image
    case pdf
    case audio
    case video
    case code
    case document

    /// Default SF Symbol representing this attachment kind.
    public var symbolName: String {
      switch self {
      case .image:
        return "photo"
      case .pdf:
        return "doc.richtext"
      case .audio:
        return "waveform"
      case .video:
        return "film"
      case .code:
        return "chevron.left.forwardslash.chevron.right"
      case .document:
        return "doc.text"
      }
    }
  }

  // MARK: - Stored Properties

  /// Stable unique identifier for the attachment.
  public let id: String

  /// Underlying storage payload (`.image`, `.file`, or `.data`).
  public var payload: Payload

  /// Display filename for the attachment (e.g., `"Architecture.pdf"`).
  public var filename: String

  /// Size of the attachment in bytes, if known.
  public var fileSize: Int64?

  /// Uniform type identifier describing the attachment content.
  public var contentType: UTType

  /// Current upload lifecycle state.
  public var uploadState: UploadState

  // MARK: - Computed Properties

  /// Alias for `fileSize` preserving terminology parity with `fileSizeBytes`.
  public var fileSizeBytes: Int64? {
    get { fileSize }
    set { fileSize = newValue }
  }

  /// Semantic category automatically inferred from `payload` and `contentType`.
  public var kind: Kind {
    Self.inferKind(payload: payload, contentType: contentType, filename: filename)
  }

  /// Clamped upload progress (`0.0...1.0`) when `uploadState` is `.uploading`, otherwise `nil`.
  public var uploadProgress: Double? {
    if case .uploading(let progress) = uploadState {
      return min(max(progress, 0.0), 1.0)
    }
    return nil
  }

  /// Error message when `uploadState` is `.failed`, otherwise `nil`.
  public var uploadError: String? {
    if case .failed(let error) = uploadState {
      return error
    }
    return nil
  }

  /// Returns `true` if and only if `uploadState == .ready` (`[MF-5]`).
  @inlinable
  public var isReadyForSubmission: Bool {
    uploadState == .ready
  }

  /// SF Symbol name representing this attachment's semantic `kind`.
  public var symbolName: String {
    kind.symbolName
  }

  /// Formatted human-readable byte count (e.g., `"2.4 MB"`), if `fileSize` is available.
  public var formattedFileSize: String? {
    guard let fileSize, fileSize >= 0 else { return nil }
    return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
  }

  /// Human-readable subtitle combining file extension / type and byte count.
  public var formattedSubtitle: String {
    if let uploadError {
      return uploadError
    }
    if let progress = uploadProgress {
      return "\(Int((progress * 100).rounded()))%"
    }
    let ext = (filename as NSString).pathExtension.uppercased()
    let typeLabel = ext.isEmpty ? (contentType.localizedDescription ?? kind.rawValue.uppercased()) : ext
    if let formattedFileSize {
      return "\(typeLabel) · \(formattedFileSize)"
    }
    return typeLabel
  }

  // MARK: - Initializers

  /// Creates a `ConversationAttachment` from an explicit `Payload` and optional metadata overrides.
  public init(
    id: String = UUID().uuidString,
    payload: Payload,
    filename: String? = nil,
    fileSize: Int64? = nil,
    contentType: UTType? = nil,
    uploadState: UploadState = .ready
  ) {
    self.id = id
    self.payload = payload
    self.uploadState = uploadState

    switch payload {
    case .image(let imageBox):
      self.filename = filename ?? "Image.png"
      self.contentType = contentType ?? Self.inferUTType(fromFilename: self.filename, fallback: .png)
      self.fileSize = fileSize ?? imageBox.pngData().map { Int64($0.count) }

    case .file(let url):
      let resolvedName = filename ?? (url.lastPathComponent.isEmpty ? "Document" : url.lastPathComponent)
      self.filename = resolvedName
      self.contentType = contentType ?? Self.inferUTType(fromURL: url, filename: resolvedName)
      if let fileSize {
        self.fileSize = fileSize
      } else if url.isFileURL,
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
        let size = resourceValues.fileSize
      {
        self.fileSize = Int64(size)
      } else {
        self.fileSize = nil
      }

    case .data(let data, let dataContentType, let dataFilename):
      let resolvedName = filename ?? (dataFilename.isEmpty ? "Attachment.bin" : dataFilename)
      self.filename = resolvedName
      self.contentType = contentType ?? dataContentType
      self.fileSize = fileSize ?? Int64(data.count)
    }
  }

  /// Creates an image attachment from a `PlatformImage` wrapped in a `PlatformImageBox`.
  public init(
    id: String = UUID().uuidString,
    image: PlatformImage,
    filename: String = "Image.png",
    uploadState: UploadState = .ready
  ) {
    let box = PlatformImageBox(image)
    self.id = id
    self.payload = .image(box)
    self.filename = filename
    self.contentType = Self.inferUTType(fromFilename: filename, fallback: .png)
    self.fileSize = nil
    self.uploadState = uploadState
  }

  /// Creates an image attachment from an existing `PlatformImageBox`.
  public init(
    id: String = UUID().uuidString,
    imageBox: PlatformImageBox,
    filename: String = "Image.png",
    uploadState: UploadState = .ready
  ) {
    self.id = id
    self.payload = .image(imageBox)
    self.filename = filename
    self.contentType = Self.inferUTType(fromFilename: filename, fallback: .png)
    self.fileSize = nil
    self.uploadState = uploadState
  }

  /// Creates a file-backed attachment from a local or security-scoped `URL`.
  public init(
    id: String = UUID().uuidString,
    fileURL: URL,
    fileSize: Int64? = nil,
    contentType: UTType? = nil,
    uploadState: UploadState = .ready
  ) {
    self.init(
      id: id,
      payload: .file(fileURL),
      filename: fileURL.lastPathComponent.isEmpty ? "Document" : fileURL.lastPathComponent,
      fileSize: fileSize,
      contentType: contentType,
      uploadState: uploadState
    )
  }

  /// Creates an in-memory data attachment with an explicit `UTType` and `filename`.
  public init(
    id: String = UUID().uuidString,
    data: Data,
    contentType: UTType,
    filename: String,
    uploadState: UploadState = .ready
  ) {
    self.id = id
    self.payload = .data(data, contentType: contentType, filename: filename)
    self.filename = filename
    self.contentType = contentType
    self.fileSize = Int64(data.count)
    self.uploadState = uploadState
  }

  // MARK: - Static Factory Convenience Methods

  /// Creates a `ConversationAttachment` wrapping a `PlatformImage`.
  public static func image(
    id: String = UUID().uuidString,
    _ image: PlatformImage,
    filename: String = "Image.png",
    uploadState: UploadState = .ready
  ) -> ConversationAttachment {
    ConversationAttachment(
      id: id,
      image: image,
      filename: filename,
      uploadState: uploadState
    )
  }

  /// Creates a `ConversationAttachment` wrapping a `PlatformImageBox`.
  public static func image(
    id: String = UUID().uuidString,
    _ imageBox: PlatformImageBox,
    filename: String = "Image.png",
    uploadState: UploadState = .ready
  ) -> ConversationAttachment {
    ConversationAttachment(
      id: id,
      imageBox: imageBox,
      filename: filename,
      uploadState: uploadState
    )
  }

  /// Creates a `ConversationAttachment` referencing a local file `URL`.
  public static func file(
    id: String = UUID().uuidString,
    url: URL,
    contentType: UTType? = nil,
    fileSizeBytes: Int64? = nil,
    uploadState: UploadState = .ready
  ) -> ConversationAttachment {
    ConversationAttachment(
      id: id,
      fileURL: url,
      fileSize: fileSizeBytes,
      contentType: contentType,
      uploadState: uploadState
    )
  }

  /// Creates a `ConversationAttachment` from in-memory `Data`.
  public static func data(
    id: String = UUID().uuidString,
    _ data: Data,
    contentType: UTType,
    filename: String,
    uploadState: UploadState = .ready
  ) -> ConversationAttachment {
    ConversationAttachment(
      id: id,
      data: data,
      contentType: contentType,
      filename: filename,
      uploadState: uploadState
    )
  }

  // MARK: - $O(1)$ Equatable & Hashable (`[MF-4]`)

  /// $O(1)$ equality check comparing metadata and stable payload identity without scanning raw `Data` buffers.
  public static func == (lhs: ConversationAttachment, rhs: ConversationAttachment) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.filename == rhs.filename,
      lhs.fileSize == rhs.fileSize,
      lhs.contentType == rhs.contentType,
      lhs.uploadState == rhs.uploadState
    else {
      return false
    }
    switch (lhs.payload, rhs.payload) {
    case (.image(let lhsBox), .image(let rhsBox)):
      return lhsBox.id == rhsBox.id
    case (.file(let lhsURL), .file(let rhsURL)):
      return lhsURL == rhsURL
    case (.data(let lhsData, _, _), .data(let rhsData, _, _)):
      return lhsData.count == rhsData.count
    default:
      return false
    }
  }

  /// $O(1)$ hash combining metadata and stable payload identity without hashing raw `Data` bytes.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(filename)
    hasher.combine(fileSize)
    hasher.combine(contentType)
    hasher.combine(uploadState)
    switch payload {
    case .image(let box):
      hasher.combine(box.id)
    case .file(let url):
      hasher.combine(url)
    case .data(let data, _, _):
      hasher.combine(data.count)
    }
  }

  // MARK: - Off-Main-Actor Thumbnail & QuickLook Delegation

  /// Generates a memory-safe downsampled thumbnail off `@MainActor` by delegating to `PlatformThumbnailGenerator.shared`.
  ///
  /// - Parameter maxPixelSize: Maximum pixel dimension for the generated thumbnail (defaults to `320`).
  /// - Returns: A downsampled `PlatformImageBox`, or `nil` if the attachment type does not support visual thumbnails.
  public func generateThumbnail(
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize
  ) async -> PlatformImageBox? {
    switch payload {
    case .image(let imageBox):
      return try? await PlatformThumbnailGenerator.shared.thumbnail(
        id: id,
        imageBox: imageBox,
        maxPixelSize: maxPixelSize
      )
    case .file(let fileURL):
      return try? await PlatformThumbnailGenerator.shared.thumbnail(
        id: id,
        fileURL: fileURL,
        contentType: contentType,
        maxPixelSize: maxPixelSize
      )
    case .data(let data, let dataContentType, _):
      return try? await PlatformThumbnailGenerator.shared.thumbnail(
        id: id,
        data: data,
        contentType: dataContentType,
        maxPixelSize: maxPixelSize
      )
    }
  }

  /// Resolves a sanitized local `URL` suitable for SwiftUI's `.quickLookPreview(_:)` off `@MainActor`.
  ///
  /// Delegates to `PlatformThumbnailGenerator.shared.resolveQuickLookURL(...)`, which prevents path traversal (`../`)
  /// and materializes in-memory `.image` or `.data` payloads inside `ConversationKitQuickLook`.
  public func resolveQuickLookURL() async throws -> URL {
    switch payload {
    case .file(let fileURL):
      if fileURL.isFileURL && FileManager.default.fileExists(atPath: fileURL.path) {
        return fileURL
      }
      return try await PlatformThumbnailGenerator.shared.resolveQuickLookURL(
        idString: id,
        filename: filename,
        dataProvider: {
          guard fileURL.isFileURL else { return nil }
          return try? Data(contentsOf: fileURL)
        }
      )
    case .image(let imageBox):
      let targetFilename = filename.isEmpty ? "Image.png" : filename
      return try await PlatformThumbnailGenerator.shared.resolveQuickLookURL(
        idString: id,
        filename: targetFilename,
        dataProvider: { imageBox.pngData() }
      )
    case .data(let data, _, let dataFilename):
      let targetFilename = dataFilename.isEmpty ? filename : dataFilename
      return try await PlatformThumbnailGenerator.shared.resolveQuickLookURL(
        idString: id,
        filename: targetFilename,
        dataProvider: { data }
      )
    }
  }

  // MARK: - Internal Inference Helpers

  internal static func inferUTType(fromURL url: URL, filename: String) -> UTType {
    if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
      let contentType = resourceValues.contentType
    {
      return contentType
    }
    return inferUTType(fromFilename: filename, fallback: .data)
  }

  internal static func inferUTType(fromFilename filename: String, fallback: UTType) -> UTType {
    let ext = (filename as NSString).pathExtension
    guard !ext.isEmpty, let inferred = UTType(filenameExtension: ext) else {
      return fallback
    }
    return inferred
  }

  internal static func inferKind(payload: Payload, contentType: UTType, filename: String) -> Kind {
    if case .image = payload {
      return .image
    }
    if contentType.conforms(to: .pdf) {
      return .pdf
    }
    if contentType.conforms(to: .image) {
      return .image
    }
    if contentType.conforms(to: .audio) {
      return .audio
    }
    if contentType.conforms(to: .movie) || contentType.conforms(to: .video) || contentType.conforms(to: .audiovisualContent) {
      return .video
    }
    if contentType.conforms(to: .sourceCode)
      || contentType.conforms(to: .script)
      || contentType.conforms(to: .json)
      || contentType.conforms(to: .xml)
      || contentType.conforms(to: .yaml)
      || contentType.conforms(to: .shellScript)
    {
      return .code
    }

    let ext = (filename as NSString).pathExtension.lowercased()
    switch ext {
    case "pdf":
      return .pdf
    case "png", "jpg", "jpeg", "heic", "heif", "gif", "webp", "tiff", "bmp", "svg":
      return .image
    case "mp3", "wav", "m4a", "aac", "flac", "ogg", "opus":
      return .audio
    case "mp4", "mov", "m4v", "webm", "avi", "mkv":
      return .video
    case "swift", "py", "js", "ts", "tsx", "jsx", "rs", "go", "c", "cpp", "h", "hpp", "m", "mm",
      "java", "kt", "rb", "php", "sh", "zsh", "bash", "json", "yaml", "yml", "toml", "xml",
      "html", "css", "scss", "sql", "md", "markdown":
      return .code
    default:
      if contentType.conforms(to: .plainText) {
        return .code
      }
      return .document
    }
  }
}

// MARK: - PlatformThumbnailGenerator Convenience Forwarding

extension PlatformThumbnailGenerator {
  /// Generates a memory-safe downsampled thumbnail for a `ConversationAttachment`.
  public func thumbnail(
    for attachment: ConversationAttachment,
    maxPixelSize: Int = PlatformThumbnailGenerator.defaultMaxPixelSize,
    scale: CGFloat = 2.0
  ) async throws -> PlatformImageBox {
    switch attachment.payload {
    case .image(let imageBox):
      return try await thumbnail(
        id: attachment.id,
        imageBox: imageBox,
        maxPixelSize: maxPixelSize,
        scale: scale
      )
    case .file(let fileURL):
      return try await thumbnail(
        id: attachment.id,
        fileURL: fileURL,
        contentType: attachment.contentType,
        maxPixelSize: maxPixelSize,
        scale: scale
      )
    case .data(let data, let contentType, _):
      return try await thumbnail(
        id: attachment.id,
        data: data,
        contentType: contentType,
        maxPixelSize: maxPixelSize,
        scale: scale
      )
    }
  }

  /// Resolves a sanitized local `URL` suitable for SwiftUI's `.quickLookPreview(_:)` for a `ConversationAttachment`.
  public func resolveQuickLookURL(for attachment: ConversationAttachment) async throws -> URL {
    try await attachment.resolveQuickLookURL()
  }
}

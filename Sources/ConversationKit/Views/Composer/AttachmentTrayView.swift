//
//  AttachmentTrayView.swift
//  ConversationKit
//
//  Pending multimodal attachments strip with off-main-actor thumbnailing, determinate
//  upload progress rings, per-item retry, remove badge, and QuickLook preview (F-4, AC-6, AC-7).
//

import QuickLook
import SwiftUI

// MARK: - AttachmentTrayView

/// Horizontal scroll tray rendered inside `MessageComposerView` that displays pending
/// `ConversationAttachment` tiles with downsampled thumbnails, determinate upload progress rings,
/// per-item retry on upload failure, removal controls, and native QuickLook inspection (`F-4`, `AC-6`, `AC-7`).
///
/// ### Usage
/// ```swift
/// AttachmentTrayView(attachments: $attachments) { failedAttachment in
///   retryUpload(failedAttachment)
/// }
/// ```
@MainActor
public struct AttachmentTrayView: View {
  /// Two-way binding to the composer's pending attachments collection.
  @Binding public var attachments: [ConversationAttachment]

  /// Optional callback invoked when the user taps Retry on a `.failed` attachment.
  public let onRetry: (@MainActor (ConversationAttachment) -> Void)?

  /// Optional callback invoked when an attachment is removed from the tray.
  public let onRemove: (@MainActor (ConversationAttachment) -> Void)?

  @Environment(\.onAttachmentRetry) private var environmentRetryAction
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var quickLookURL: URL?

  /// Creates an `AttachmentTrayView` bound to a `[ConversationAttachment]` collection.
  ///
  /// - Parameters:
  ///   - attachments: Binding to the array of pending `ConversationAttachment` values.
  ///   - onRetry: Optional callback invoked when Retry is tapped on a `.failed` attachment.
  ///   - onRemove: Optional callback invoked when an attachment is removed.
  public init(
    attachments: Binding<[ConversationAttachment]>,
    onRetry: (@MainActor (ConversationAttachment) -> Void)? = nil,
    onRemove: (@MainActor (ConversationAttachment) -> Void)? = nil
  ) {
    self._attachments = attachments
    self.onRetry = onRetry
    self.onRemove = onRemove
  }

  /// Convenience initializer accepting an unlabeled `Binding<[ConversationAttachment]>`.
  public init(
    _ attachments: Binding<[ConversationAttachment]>,
    onRetry: (@MainActor (ConversationAttachment) -> Void)? = nil
  ) {
    self._attachments = attachments
    self.onRetry = onRetry
    self.onRemove = nil
  }

  public var body: some View {
    if !attachments.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(attachments) { attachment in
            AttachmentPreviewCard(
              attachment: attachment,
              onTap: {
                openQuickLookIfReady(for: attachment)
              },
              onRemove: {
                removeAttachment(attachment)
              },
              onRetry: {
                retryAttachment(attachment)
              }
            )
            .accessibilityIdentifier(ConversationAccessibilityID.attachmentTile(attachment.id))
          }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
      }
      .quickLookPreview($quickLookURL)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(ConversationAccessibilityID.composerAttachmentTray)
    }
  }

  private func openQuickLookIfReady(for attachment: ConversationAttachment) {
    guard attachment.uploadState == .ready else { return }
    PlatformHapticEvent.triggerHaptic(.selection)
    Task { @MainActor in
      if let resolvedURL = try? await attachment.resolveQuickLookURL() {
        quickLookURL = resolvedURL
      }
    }
  }

  private func removeAttachment(_ attachment: ConversationAttachment) {
    PlatformHapticEvent.triggerHaptic(.selection)
    if let onRemove {
      onRemove(attachment)
    } else if reduceMotion {
      attachments.removeAll { $0.id == attachment.id }
    } else {
      withAnimation(.snappy(duration: 0.22)) {
        attachments.removeAll { $0.id == attachment.id }
      }
    }
  }

  private func retryAttachment(_ attachment: ConversationAttachment) {
    PlatformHapticEvent.triggerHaptic(.selection)
    if let onRetry {
      onRetry(attachment)
    } else if let environmentRetryAction {
      Task { @MainActor in
        await environmentRetryAction(attachment)
      }
    }
  }
}

// MARK: - AttachmentPreviewCard

/// Individual preview tile inside `AttachmentTrayView` rendering either a `72×72pt` concentric
/// image thumbnail tile or a structured document card (`PDF`, `audio`, `code`, `document`)
/// with upload progress rings, retry overlay, and remove badge (`F-4`, `AC-6`, `AC-7`).
@MainActor
public struct AttachmentPreviewCard: View {
  /// The attachment represented by this preview card.
  public let attachment: ConversationAttachment

  /// Action invoked when the user taps a `.ready` tile to inspect via QuickLook.
  public let onTap: @MainActor () -> Void

  /// Action invoked when the user taps the top-trailing remove button.
  public let onRemove: @MainActor () -> Void

  /// Optional action invoked when the user taps Retry on a `.failed` tile.
  public let onRetry: (@MainActor () -> Void)?

  @State private var thumbnailBox: PlatformImageBox?

  private static let tileSize: CGFloat = 72
  private static let cornerRadius: CGFloat = 14

  /// Creates an `AttachmentPreviewCard`.
  public init(
    attachment: ConversationAttachment,
    onTap: @escaping @MainActor () -> Void = {},
    onRemove: @escaping @MainActor () -> Void,
    onRetry: (@MainActor () -> Void)? = nil
  ) {
    self.attachment = attachment
    self.onTap = onTap
    self.onRemove = onRemove
    self.onRetry = onRetry
  }

  public var body: some View {
    ZStack(alignment: .topTrailing) {
      mainCardButton

      removeBadgeButton
        .offset(x: 5, y: -5)
    }
    .padding(.top, 5)
    .padding(.trailing, 5)
    .task(id: attachment.id) {
      if let cached = await PlatformThumbnailGenerator.shared.cachedThumbnail(
        for: attachment.id,
        maxPixelSize: 320
      ) {
        thumbnailBox = cached
        return
      }
      thumbnailBox = await attachment.generateThumbnail(maxPixelSize: 320)
    }
  }

  // MARK: - Card Base & Upload State Overlays

  @ViewBuilder
  private var mainCardButton: some View {
    Button {
      if attachment.uploadState == .ready {
        onTap()
      } else if case .failed = attachment.uploadState {
        onRetry?()
      }
    } label: {
      Group {
        if attachment.kind == .image {
          imageTileContent
        } else {
          documentCardContent
        }
      }
      .overlay {
        uploadStateOverlay
      }
      .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
          .strokeBorder(borderColor, lineWidth: isFailed ? 1.25 : 0.5)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(cardAccessibilityLabel)
    .accessibilityValue(cardAccessibilityValue)
    .accessibilityHint(cardAccessibilityHint)
  }

  @ViewBuilder
  private var imageTileContent: some View {
    ZStack {
      Color.platformTertiaryBackground

      if let thumbnailBox {
        thumbnailBox.swiftUIImage
          .resizable()
          .scaledToFill()
          .frame(width: Self.tileSize, height: Self.tileSize)
          .clipped()
      } else {
        Image(systemName: "photo")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: Self.tileSize, height: Self.tileSize)
  }

  @ViewBuilder
  private var documentCardContent: some View {
    HStack(spacing: 10) {
      documentThumbnailOrIcon

      VStack(alignment: .leading, spacing: 4) {
        Text(attachment.filename)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.middle)

        HStack(spacing: 6) {
          Text(fileExtensionBadgeText)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(kindAccentColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
              kindAccentColor.opacity(0.14),
              in: RoundedRectangle(cornerRadius: 4, style: .continuous)
            )

          if let formattedSize = attachment.formattedFileSize {
            Text(formattedSize)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else {
            Text(attachment.kind.rawValue.capitalized)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        if case .failed(let errorMessage) = attachment.uploadState {
          Text(errorMessage)
            .font(.caption2)
            .foregroundStyle(.red)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .frame(minWidth: 176, maxWidth: 224, minHeight: Self.tileSize, maxHeight: Self.tileSize)
    .background(Color.platformTertiaryBackground)
  }

  @ViewBuilder
  private var documentThumbnailOrIcon: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(kindAccentColor.opacity(0.12))

      if let thumbnailBox {
        thumbnailBox.swiftUIImage
          .resizable()
          .scaledToFill()
          .frame(width: 42, height: 54)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      } else {
        Image(systemName: attachment.symbolName)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(kindAccentColor)
      }
    }
    .frame(width: 42, height: 54)
  }

  // MARK: - Upload State Overlay (`AC-7`)

  @ViewBuilder
  private var uploadStateOverlay: some View {
    switch attachment.uploadState {
    case .ready:
      EmptyView()

    case .uploading(let rawProgress):
      let progress = min(max(rawProgress, 0.0), 1.0)
      ZStack {
        Color.black.opacity(0.45)

        ProgressView(value: progress, total: 1.0)
          .progressViewStyle(.circular)
          .tint(.white)
          .controlSize(.regular)
          .accessibilityIdentifier(
            ConversationAccessibilityID.attachmentUploadProgress(attachment.id)
          )
          .accessibilityLabel("Upload progress")
          .accessibilityValue("\(Int((progress * 100).rounded())) percent")
      }

    case .failed:
      ZStack {
        Color.black.opacity(0.50)

        Button {
          onRetry?()
        } label: {
          VStack(spacing: 3) {
            Image(systemName: "arrow.clockwise")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 30, height: 30)
              .background(Color.red.opacity(0.9), in: Circle())

            Text("Retry")
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(.white)
          }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
          ConversationAccessibilityID.attachmentRetryButton(attachment.id)
        )
        .accessibilityLabel("Retry upload for \(attachment.filename)")
      }
    }
  }

  @ViewBuilder
  private var removeBadgeButton: some View {
    Button {
      onRemove()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 18, weight: .semibold))
        .symbolRenderingMode(.palette)
        .foregroundStyle(.white, Color.black.opacity(0.68))
        .background(Circle().fill(Color.platformSecondaryBackground.opacity(0.2)))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(
      ConversationAccessibilityID.attachmentRemoveButton(attachment.id)
    )
    .accessibilityLabel("Remove \(attachment.filename)")
  }

  // MARK: - Helpers

  private var isFailed: Bool {
    if case .failed = attachment.uploadState {
      return true
    }
    return false
  }

  private var borderColor: Color {
    if isFailed {
      return .red.opacity(0.85)
    }
    return Color.platformSeparator.opacity(0.45)
  }

  private var fileExtensionBadgeText: String {
    let ext = (attachment.filename as NSString).pathExtension.uppercased()
    if !ext.isEmpty {
      return String(ext.prefix(6))
    }
    return attachment.kind.rawValue.uppercased()
  }

  private var kindAccentColor: Color {
    switch attachment.kind {
    case .image:
      return .blue
    case .pdf:
      return .red
    case .audio:
      return .orange
    case .video:
      return .purple
    case .code:
      return .indigo
    case .document:
      return .accentColor
    }
  }

  private var cardAccessibilityLabel: String {
    "\(attachment.filename), \(attachment.kind.rawValue)"
  }

  private var cardAccessibilityValue: String {
    switch attachment.uploadState {
    case .ready:
      return attachment.formattedFileSize ?? "Ready"
    case .uploading(let progress):
      return "Uploading \(Int((min(max(progress, 0.0), 1.0) * 100).rounded())) percent"
    case .failed(let error):
      return "Upload failed: \(error)"
    }
  }

  private var cardAccessibilityHint: String {
    switch attachment.uploadState {
    case .ready:
      return "Double-tap to preview attachment with QuickLook"
    case .uploading:
      return "Attachment is currently uploading"
    case .failed:
      return "Double-tap to retry uploading attachment"
    }
  }
}

#Preview("AttachmentTrayView") {
  @Previewable @State var attachments: [ConversationAttachment] = [
    ConversationAttachment(
      id: "img-ready",
      imageBox: PlatformImageBox.solidColor(red: 0.25, green: 0.55, blue: 0.95)
        ?? PlatformImageBox(data: Data())!,
      filename: "Diagram.png",
      uploadState: .ready
    ),
    ConversationAttachment(
      id: "pdf-uploading",
      data: Data(repeating: 0x25, count: 248_000),
      contentType: .pdf,
      filename: "ADR-0001-Architecture.pdf",
      uploadState: .uploading(progress: 0.45)
    ),
    ConversationAttachment(
      id: "code-failed",
      data: Data("struct ChatView: View {}".utf8),
      contentType: .swiftSource,
      filename: "ConversationView.swift",
      uploadState: .failed(error: "Network timeout")
    )
  ]

  AttachmentTrayView(attachments: $attachments) { failed in
    if let index = attachments.firstIndex(where: { $0.id == failed.id }) {
      attachments[index].uploadState = .ready
    }
  }
  .padding()
}

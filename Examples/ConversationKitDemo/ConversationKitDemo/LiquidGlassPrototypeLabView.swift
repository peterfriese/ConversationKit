//
//  LiquidGlassPrototypeLabView.swift
//  ConversationKitDemo
//
//  Interactive 5-prototype Liquid Glass laboratory contrasting legacy anti-patterns
//  against canonical iOS 26 / macOS 26 Liquid Glass patterns from Sofia & Apple HIG.
//

import ConversationKit
import SwiftUI

// MARK: - Prototype Kind

enum LiquidGlassPrototypeTab: String, CaseIterable, Identifiable, Sendable {
  case p1SiblingBar = "P1: Sibling Bar"
  case p2NativeMenu = "P2: Native Menu"
  case p3CircularGlass = "P3: Circular Glass"
  case p4SafeAreaBar = "P4: SafeAreaBar"
  case p5AdaptiveDensity = "P5: Adaptive Density"

  var id: String { rawValue }

  var shortCode: String {
    switch self {
    case .p1SiblingBar: return "P1"
    case .p2NativeMenu: return "P2"
    case .p3CircularGlass: return "P3"
    case .p4SafeAreaBar: return "P4"
    case .p5AdaptiveDensity: return "P5"
    }
  }

  var subtitle: String {
    switch self {
    case .p1SiblingBar:
      return "P1-SofiaSiblingBar — 3-Zone Sibling Architecture & Morphing vs. 3pt Dog-Bone & 4-Button Inner Farm"
    case .p2NativeMenu:
      return "P2-NativeMenuInGlass — Native SwiftUI Menu inside Quiet Vessel vs. .interactive() Container Hijack"
    case .p3CircularGlass:
      return "P3-CircularGlassGeometry — True 44×44pt Circular Glass vs. .buttonStyle(.glass) Oval Distortion"
    case .p4SafeAreaBar:
      return "P4-SafeAreaBarOptics — Pure .safeAreaBar(edge: .bottom) + .scrollEdgeEffectStyle(.soft) vs. LinearGradient Shroud"
    case .p5AdaptiveDensity:
      return "P5-AdaptiveDensity — Sofia Adaptive Accessory Compression & Sibling Coalescence"
    }
  }
}

// MARK: - LiquidGlassPrototypeLabView

struct LiquidGlassPrototypeLabView: View {
  var onClose: (() -> Void)?

  @State private var selectedTab: LiquidGlassPrototypeTab = {
    let args = ProcessInfo.processInfo.arguments
    if let idx = args.firstIndex(of: "-prototype"), idx + 1 < args.count {
      let code = args[idx + 1].uppercased()
      if let match = LiquidGlassPrototypeTab.allCases.first(where: { $0.shortCode == code }) {
        return match
      }
    }
    return .p1SiblingBar
  }()

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        prototypeSelectorHeader

        Divider()

        Group {
          switch selectedTab {
          case .p1SiblingBar:
            P1SofiaSiblingBarPrototype()
          case .p2NativeMenu:
            P2NativeMenuInGlassPrototype()
          case .p3CircularGlass:
            P3CircularGlassGeometryPrototype()
          case .p4SafeAreaBar:
            P4SafeAreaBarOpticsPrototype()
          case .p5AdaptiveDensity:
            P5AdaptiveDensityPrototype()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .navigationTitle("Liquid Glass Lab")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        if let onClose {
          ToolbarItem(placement: .cancellationAction) {
            Button("Close", systemImage: "xmark") {
              onClose()
            }
            .accessibilityIdentifier("prototypeLab.closeButton")
          }
        }
      }
    }
    .accessibilityIdentifier("prototypeLab.rootView")
  }

  private var prototypeSelectorHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(LiquidGlassPrototypeTab.allCases) { tab in
            let isSelected = (selectedTab == tab)
            Button {
              withAnimation(.snappy(duration: 0.22)) {
                selectedTab = tab
              }
            } label: {
              Text(tab.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                  isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                  in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("prototypeLab.tab.\(tab.shortCode)")
          }
        }
        .padding(.horizontal, 16)
      }

      Text(selectedTab.subtitle)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 10)
    .background(Color.platformSecondaryBackground.opacity(0.6))
  }
}

// MARK: - P1: P1-SofiaSiblingBar

private struct P1SofiaSiblingBarPrototype: View {
  @State private var draftText: String = "Explain Liquid Glass morphing"
  @FocusState private var isPillFocused: Bool
  @State private var isSimulatedGenerating: Bool = false
  @State private var selectedModel: String = "Claude Sonnet 4.6"
  @State private var selectedContainerSpacing: CGFloat = 12
  @Namespace private var canonicalNamespace

  private let containerSpacings: [CGFloat] = [8, 10, 12, 14, 16]

  private var canSubmit: Bool {
    !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var showsSubmit: Bool {
    canSubmit || isSimulatedGenerating
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        stateControlsCard

        // 1. Canonical Pure Native SwiftUI GlassEffectContainer + .glassEffect(.regular.interactive())
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Label("CANONICAL: Pure Native GlassEffectContainer + .interactive()", systemImage: "checkmark.seal.fill")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.green)

            Spacer()

            Text("spacing: \(Int(selectedContainerSpacing))pt / HStack: 8pt")
              .font(.caption2.monospaced().weight(.bold))
              .foregroundStyle(Color.accentColor)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.accentColor.opacity(0.14), in: Capsule())
              .accessibilityIdentifier("p1.spacingBadge")
          }

          Text("100% pure, static SwiftUI: GlassEffectContainer(spacing: \(Int(selectedContainerSpacing))) + static HStack(alignment: .bottom, spacing: 8). Zero timers, zero .scaleEffect hacks, zero dynamic spacing mutation! When you press any .glassEffect(.regular.interactive()) surface, iOS 26's native C++/Metal shader expands the glass during the touch and settles when released.")
            .font(.caption)
            .foregroundStyle(.secondary)

          canonicalSofiaComposerBar(containerSpacing: selectedContainerSpacing)
            .padding(.vertical, 10)
            .background(colourfulBackdrop)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        // 2. Side-by-Side Static GlassEffectContainer(spacing:) Comparison (8pt, 12pt, 16pt)
        VStack(alignment: .leading, spacing: 10) {
          Label("COMPARISON: Static GlassEffectContainer(spacing: 8 vs 12 vs 16)", systemImage: "square.stack.3d.forward.dottedline")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)

          Text("Compare how GlassEffectContainer(spacing:) controls the metaball merge threshold against a fixed HStack(spacing: 8) without mutating layout spacing:")
            .font(.caption)
            .foregroundStyle(.secondary)

          ForEach([8, 12, 16], id: \.self) { spacingValue in
            VStack(alignment: .leading, spacing: 4) {
              Text("GlassEffectContainer(spacing: \(spacingValue)) · HStack(spacing: 8)")
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)

              canonicalSofiaComposerBar(containerSpacing: CGFloat(spacingValue))
                .padding(.vertical, 8)
                .background(colourfulBackdrop)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
          }
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        // 3. Abused Legacy Layout (Static 3pt Dog-Bone)
        VStack(alignment: .leading, spacing: 8) {
          Label("VETOED: Static 3pt Dog-Bone & 4-Button Inner Farm", systemImage: "xmark.octagon.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)

          Text("Abuses: (1) spacing: isFocused ? 3 : 8 stays permanently stuck at 3pt while focused, creating a permanent dog-bone neck, (2) 4 buttons (156pt) crammed inside the text pill with nested strokeBorder rings.")
            .font(.caption)
            .foregroundStyle(.secondary)

          abusedLegacyComposerBar
            .padding(.vertical, 8)
            .background(colourfulBackdrop)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .padding(16)
    }
    .accessibilityIdentifier("prototypeLab.p1")
  }

  private var stateControlsCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Native GlassEffectContainer(spacing:) & State Controls")
        .font(.caption.weight(.bold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      HStack(spacing: 6) {
        ForEach(containerSpacings, id: \.self) { spacing in
          let isSelected = (selectedContainerSpacing == spacing)
          Button {
            selectedContainerSpacing = spacing
          } label: {
            Text("\(Int(spacing))pt")
              .font(.caption2.monospaced().weight(.semibold))
              .foregroundStyle(isSelected ? Color.white : Color.primary)
              .padding(.horizontal, 10)
              .padding(.vertical, 7)
              .frame(maxWidth: .infinity)
              .background(
                isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("p1.spacing.\(Int(spacing))")
        }
      }

      HStack(spacing: 12) {
        Toggle("Focused", isOn: Binding(
          get: { isPillFocused },
          set: { isPillFocused = $0 }
        ))
        .toggleStyle(.button)
        .accessibilityIdentifier("p1.toggleFocused")

        Toggle("Has Text", isOn: Binding(
          get: { !draftText.isEmpty },
          set: { hasText in
            withAnimation(.snappy(duration: 0.25)) {
              draftText = hasText ? "Explain Liquid Glass morphing" : ""
            }
          }
        ))
        .toggleStyle(.button)
        .accessibilityIdentifier("p1.toggleHasText")

        Toggle("Generating", isOn: $isSimulatedGenerating.animation(.snappy(duration: 0.25)))
          .toggleStyle(.button)
          .accessibilityIdentifier("p1.toggleGenerating")
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var abusedLegacyComposerBar: some View {
    GlassEffectContainer(spacing: 8) {
      HStack(alignment: .bottom, spacing: isPillFocused ? 3 : 8) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .medium))
          .frame(width: 44, height: 44)
          .glassEffect(.regular.interactive(), in: .circle)

        HStack(alignment: .bottom, spacing: 0) {
          TextField("Message…", text: $draftText)
            .textFieldStyle(.plain)
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .padding(.vertical, 10)

          HStack(alignment: .bottom, spacing: 6) {
            // Nested strokeBorder circle inside glass
            Image(systemName: "sparkles")
              .font(.system(size: 14, weight: .semibold))
              .frame(width: 32, height: 32)
              .background(Color.primary.opacity(0.06), in: Circle())
              .overlay {
                Circle().strokeBorder(Color.secondary.opacity(0.45), lineWidth: 0.5)
              }

            Image(systemName: "waveform")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)

            if isPillFocused {
              Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
            }

            if showsSubmit {
              Image(systemName: isSimulatedGenerating ? "stop.fill" : "arrow.up")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentColor, in: Circle())
            }
          }
          .padding(.trailing, 6)
          .padding(.bottom, 6)
        }
        .frame(minHeight: 44)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
      }
    }
    .padding(.horizontal, 12)
  }

  private func canonicalSofiaComposerBar(containerSpacing: CGFloat) -> some View {
    GlassEffectContainer(spacing: containerSpacing) {
      HStack(alignment: .bottom, spacing: 8) {
        // Outside Left: 44×44pt Leading Attachment Menu Sibling
        Menu {
          Button("Photos", systemImage: "photo.on.rectangle.angled") {}
          Button("Files", systemImage: "doc.badge.plus") {}
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("p1.leadingPlus.\(Int(containerSpacing))", in: canonicalNamespace)

        // Inside the Interactive Text Vessel: TextField + 32×32pt Inner Trailing Accessories (Model + DismissKeyboard)
        TextField("Message…", text: $draftText)
          .textFieldStyle(.plain)
          .focused($isPillFocused)
          .padding(.leading, 14)
          .padding(.trailing, isPillFocused ? 78 : 42)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
          .glassEffectID("p1.textPill.\(Int(containerSpacing))", in: canonicalNamespace)
          .overlay(alignment: .bottomTrailing) {
            HStack(alignment: .bottom, spacing: 4) {
              Menu {
                Picker("Model", selection: $selectedModel) {
                  Text("Claude Sonnet 4.6").tag("Claude Sonnet 4.6")
                  Text("Claude Opus 4.6").tag("Claude Opus 4.6")
                  Text("Gemini 3 Pro").tag("Gemini 3 Pro")
                }
              } label: {
                ZStack(alignment: .topTrailing) {
                  Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                  Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .padding(.top, 2)
                    .padding(.trailing, 2)
                }
                .frame(width: 32, height: 32)
                .contentShape(Circle())
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("p1.modelSelectorMenu.\(Int(containerSpacing))")

              if isPillFocused {
                Button {
                  isPillFocused = false
                } label: {
                  Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
              }
            }
            .padding(.trailing, 6)
            .padding(.bottom, 6)
            .animation(.snappy(duration: 0.22), value: isPillFocused)
          }

        // Outside Right: 44×44pt Prominent Tinted Submit/Stop Glass Sibling
        if showsSubmit {
          Button {
            withAnimation(.snappy(duration: 0.25)) {
              isSimulatedGenerating.toggle()
            }
          } label: {
            Image(systemName: isSimulatedGenerating ? "stop.fill" : "arrow.up")
              .font(.system(size: isSimulatedGenerating ? 13 : 16, weight: .semibold))
              .foregroundStyle(.white)
              .frame(width: 44, height: 44)
              .contentShape(Circle())
          }
          .buttonStyle(.plain)
          .frame(width: 44, height: 44)
          .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
          .glassEffectID("p1.submit.\(Int(containerSpacing))", in: canonicalNamespace)
          .glassEffectTransition(.matchedGeometry)
        }
      }
      .animation(.snappy(duration: 0.24), value: showsSubmit)
    }
    .padding(.horizontal, 12)
  }

  private var colourfulBackdrop: some View {
    LinearGradient(
      colors: [
        Color.blue.opacity(0.28),
        Color.indigo.opacity(0.24),
        Color.purple.opacity(0.22),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}

// MARK: - P2: P2-NativeMenuInGlass

private struct P2NativeMenuInGlassPrototype: View {
  @State private var selectedModel: ComposerModelOption? = ContentView.availableModels.first
  @State private var activeCapabilities: Set<ComposerCapability> = [.think, .search]
  @State private var sampleDraft: String = "Tap the model menu on each row…"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // 1. Why Menu Failed Previously
        VStack(alignment: .leading, spacing: 8) {
          Label("ROOT CAUSE: Menu inside .glassEffect(.regular.interactive())", systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)

          Text("When the outer text container applies .interactive(), UIKit's UIContextMenuInteraction attaches to the entire interactive glass container rather than the child Menu trigger.")
            .font(.caption)
            .foregroundStyle(.secondary)

          GlassEffectContainer(spacing: 12) {
            HStack {
              Text("Outer Vessel (.regular.interactive())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 14)

              Spacer()

              Menu {
                Section("Models") {
                  ForEach(ContentView.availableModels) { model in
                    Button(model.name) {
                      selectedModel = model
                    }
                  }
                }
              } label: {
                Label(selectedModel?.name ?? "Model", systemImage: "sparkles")
                  .font(.caption.weight(.semibold))
                  .padding(.horizontal, 10)
                  .padding(.vertical, 6)
              }
              .padding(.trailing, 8)
            }
            .frame(minHeight: 44)
            .glassEffect(.regular.interactive(), in: .capsule)
          }
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        // 2. Canonical Fix: Native SwiftUI Menu Overlaid on .glassEffect(.regular.interactive()) Vessel
        VStack(alignment: .leading, spacing: 8) {
          Label("CANONICAL FIX: Menu in .overlay(alignment: .bottomTrailing) above .interactive() Vessel", systemImage: "checkmark.seal.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.green)

          Text("By applying .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22)) to the text vessel (without .glassEffectID) and hosting innerTrailingAccessories in .overlay(alignment: .bottomTrailing), the vessel retains full interactive touch inflation while ComposerModelSelectorMenu opens its native UIMenu without vanishing the composer pill!")
            .font(.caption)
            .foregroundStyle(.secondary)

          GlassEffectContainer(spacing: 9) {
            TextField("Ask anything…", text: $sampleDraft)
              .textFieldStyle(.plain)
              .padding(.leading, 14)
              .padding(.trailing, 42)
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
              .glassEffect(.regular.interactive(), in: .capsule)
              .overlay(alignment: .bottomTrailing) {
                ComposerModelSelectorMenu(
                  models: ContentView.availableModels,
                  selectedModel: $selectedModel,
                  capabilities: [.think, .search, .image],
                  activeCapabilities: $activeCapabilities,
                  isCompact: true
                )
                .padding(.trailing, 6)
                .padding(.bottom, 6)
              }
          }

          HStack {
            Text("Full Pill Mode (CardGlass):")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
            ComposerModelSelectorMenu(
              models: ContentView.availableModels,
              selectedModel: $selectedModel,
              capabilities: [.think, .search, .image],
              activeCapabilities: $activeCapabilities,
              isCompact: false
            )
          }
          .padding(.top, 6)
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .padding(16)
    }
    .accessibilityIdentifier("prototypeLab.p2")
  }
}

// MARK: - P3: P3-CircularGlassGeometry

private struct P3CircularGlassGeometryPrototype: View {
  @State private var distortedGlassSize: CGSize = .zero
  @State private var canonicalCircleSize: CGSize = .zero
  @State private var canonicalTintedSize: CGSize = .zero
  @State private var hasUnreadBelowFold: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // 1. Oval Distortion (.buttonStyle(.glass) + .buttonBorderShape(.circle))
        VStack(alignment: .leading, spacing: 10) {
          Label("ABUSE 6: .buttonStyle(.glass) + .buttonBorderShape(.circle)", systemImage: "xmark.octagon.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)

          Text("Sofia Part 9 Finding: GlassButtonStyle applies horizontal capsule padding (~13pt each side) before applying .buttonBorderShape(.circle), turning single-icon buttons into wide ovals.")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(spacing: 20) {
            Button {} label: {
              Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .onGeometryChange(for: CGSize.self) { proxy in
              proxy.size
            } action: { newSize in
              distortedGlassSize = newSize
            }

            VStack(alignment: .leading, spacing: 4) {
              Text("Measured Frame: \(Int(distortedGlassSize.width.rounded()))×\(Int(distortedGlassSize.height.rounded()))pt")
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(.red)
              Text("Aspect Ratio: \(String(format: "%.2f", distortedGlassSize.height > 0 ? distortedGlassSize.width / distortedGlassSize.height : 1.0)) (Not 1.00!)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            }
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        // 2. Canonical True 44×44pt Circular Glass (Sofia Part 9)
        VStack(alignment: .leading, spacing: 10) {
          Label("CANONICAL (Sofia Part 9): 44×44pt Square Frame + .glassEffect(..., in: .circle)", systemImage: "checkmark.seal.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.green)

          Text("Framing the label to an exact 1:1 square (44×44pt or 40×40pt) with .buttonStyle(.plain) and .glassEffect(.regular.interactive(), in: .circle) guarantees a 1.00 aspect ratio circle.")
            .font(.caption)
            .foregroundStyle(.secondary)

          GlassEffectContainer(spacing: 12) {
            HStack(spacing: 16) {
              Button {} label: {
                Image(systemName: "plus")
                  .font(.system(size: 18, weight: .medium))
                  .foregroundStyle(.primary)
                  .frame(width: 44, height: 44)
                  .contentShape(Circle())
              }
              .buttonStyle(.plain)
              .frame(width: 44, height: 44)
              .glassEffect(.regular.interactive(), in: .circle)
              .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
              } action: { newSize in
                canonicalCircleSize = newSize
              }

              Button {} label: {
                Image(systemName: "arrow.up")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.white)
                  .frame(width: 44, height: 44)
                  .contentShape(Circle())
              }
              .buttonStyle(.plain)
              .frame(width: 44, height: 44)
              .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
              .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
              } action: { newSize in
                canonicalTintedSize = newSize
              }

              ScrollToBottomButton(hasUnreadBelowFold: hasUnreadBelowFold) {
                withAnimation(.snappy(duration: 0.22)) {
                  hasUnreadBelowFold.toggle()
                }
              }
            }
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

          HStack(spacing: 16) {
            Text("Plus Circle: \(Int(canonicalCircleSize.width.rounded()))×\(Int(canonicalCircleSize.height.rounded()))pt")
              .font(.caption.monospaced().weight(.semibold))
              .foregroundStyle(.green)

            Text("Tinted Send: \(Int(canonicalTintedSize.width.rounded()))×\(Int(canonicalTintedSize.height.rounded()))pt")
              .font(.caption.monospaced().weight(.semibold))
              .foregroundStyle(.green)
          }

          Toggle("ScrollToBottomButton Unread Capsule Mode", isOn: $hasUnreadBelowFold.animation(.snappy(duration: 0.22)))
            .font(.caption)
            .accessibilityIdentifier("p3.toggleUnreadCapsule")
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .padding(16)
    }
    .accessibilityIdentifier("prototypeLab.p3")
  }
}

// MARK: - P4: P4-SafeAreaBarOptics

private struct P4SafeAreaBarOpticsPrototype: View {
  @State private var useOpaqueGradientShroud: Bool = false
  @State private var draftText: String = ""

  private let sampleBubbles: [(title: String, detail: String, color: Color)] = [
    ("Optical Refraction Check #1", "Scroll this vibrant card behind the bottom composer bar to observe real-time Liquid Glass refraction and .scrollEdgeEffectStyle(.soft, for: .bottom).", .blue),
    ("Optical Refraction Check #2", "When the legacy 4-stop LinearGradient shroud is enabled, solid Color.platformBackground blocks all light from reaching the glass.", .purple),
    ("Optical Refraction Check #3", "With pure .safeAreaBar(edge: .bottom), iOS 26 applies progressive edge blur and specular lensing as content passes beneath the bar.", .indigo),
    ("Optical Refraction Check #4", "Notice how the 44×44pt + button and 44pt text capsule independently refract the colors of each bubble below.", .teal),
    ("Optical Refraction Check #5", "Suggestion chips and the composer float effortlessly above the timeline without an artificial opaque shelf.", .orange),
    ("Optical Refraction Check #6", "Keep scrolling to verify smooth edge transition at the bottom of the viewport.", .pink),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(useOpaqueGradientShroud ? "Legacy Opaque LinearGradient Shroud (VETOED)" : "Pure .safeAreaBar + .scrollEdgeEffectStyle(.soft) (CANONICAL)")
              .font(.caption.weight(.bold))
              .foregroundStyle(useOpaqueGradientShroud ? .red : .green)
            Text("Toggle to compare bottom bar optical transmission while scrolling.")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Toggle("Shroud", isOn: $useOpaqueGradientShroud.animation(.snappy(duration: 0.22)))
            .labelsHidden()
            .accessibilityIdentifier("p4.toggleShroud")
        }
        .padding(12)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        ForEach(Array(sampleBubbles.enumerated()), id: \.offset) { _, item in
          VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
              .font(.subheadline.weight(.bold))
              .foregroundStyle(.white)
            Text(item.detail)
              .font(.caption)
              .foregroundStyle(.white.opacity(0.92))
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            LinearGradient(
              colors: [item.color, item.color.opacity(0.75)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
          )
        }
      }
      .padding(16)
    }
    .scrollEdgeEffectStyle(.soft, for: .bottom)
    .safeAreaBar(edge: .bottom, spacing: 0) {
      VStack(spacing: 4) {
        MessageComposerView(
          text: $draftText,
          placeholder: "Scroll colorful cards behind me…"
        )
      }
      .background(alignment: .bottom) {
        if useOpaqueGradientShroud {
          LinearGradient(
            stops: [
              .init(color: Color.platformBackground.opacity(0.0), location: 0.0),
              .init(color: Color.platformBackground.opacity(0.88), location: 0.28),
              .init(color: Color.platformBackground, location: 0.55),
              .init(color: Color.platformBackground, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          .ignoresSafeArea(edges: .bottom)
        }
      }
    }
    .accessibilityIdentifier("prototypeLab.p4")
  }
}

// MARK: - P5: P5-AdaptiveDensity

private struct P5AdaptiveDensityPrototype: View {
  @State private var draftText: String = ""
  @State private var isFocused: Bool = false
  @State private var isGenerating: Bool = false
  @State private var selectedModel: ComposerModelOption? = ContentView.availableModels.first
  @State private var activeCapabilities: Set<ComposerCapability> = [.think]
  @Namespace private var densityNamespace

  private var canSubmit: Bool {
    !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var showsSubmit: Bool {
    canSubmit || isGenerating
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 10) {
          Label("P5: Sofia Adaptive Accessory Density & Morphing", systemImage: "sparkles.rectangle.stack")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)

          Text("Bookend sibling layout: Outside Left is the 44×44pt + Attachment circle sibling, Inside the quiet 44pt text vessel sit the TextField and borderless 32×32pt secondary controls (Model Menu, Dictation, and focus-driven Dismiss Keyboard), and Outside Right is the 44×44pt Prominent Tinted Send/Stop sibling.")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(spacing: 10) {
            Button(isFocused ? "Unfocus" : "Focus Composer") {
              withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                isFocused.toggle()
              }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityIdentifier("p5.toggleFocus")

            Button(draftText.isEmpty ? "Fill Sample Prompt" : "Clear Prompt") {
              withAnimation(.snappy(duration: 0.25)) {
                draftText = draftText.isEmpty ? "Compare Sofia's 3-zone Liquid Glass bar with ConversationKit" : ""
              }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityIdentifier("p5.toggleDraft")

            Button(isGenerating ? "Stop Stream" : "Simulate Stream") {
              withAnimation(.snappy(duration: 0.25)) {
                isGenerating.toggle()
              }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityIdentifier("p5.toggleStream")
          }
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        // Live Production ClassicGlassMessageComposerStyle Preview
        VStack(alignment: .leading, spacing: 8) {
          Text("Live Production MessageComposerView (.classicGlass)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)

          MessageComposerView(
            text: $draftText,
            isFocused: $isFocused,
            isGenerating: isGenerating,
            placeholder: "Message…",
            onSubmit: {
              withAnimation(.snappy(duration: 0.25)) {
                draftText = ""
                isFocused = false
              }
            },
            onStop: {
              withAnimation(.snappy(duration: 0.25)) {
                isGenerating = false
              }
            }
          )
          .composerModels(ContentView.availableModels, selection: $selectedModel)
          .composerCapabilities([.think, .search, .image], active: $activeCapabilities)
          .messageComposerStyle(.classicGlass)
          .padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [.indigo.opacity(0.25), .blue.opacity(0.20), .teal.opacity(0.20)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
          )
        }
        .padding(14)
        .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .padding(16)
    }
    .accessibilityIdentifier("prototypeLab.p5")
  }
}

#Preview("Liquid Glass Prototype Lab") {
  LiquidGlassPrototypeLabView()
}

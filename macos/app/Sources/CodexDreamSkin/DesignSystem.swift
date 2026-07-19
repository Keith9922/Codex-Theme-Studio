import SwiftUI

enum StudioColors {
  static let canvas = Color(red: 0.055, green: 0.059, blue: 0.073)
  static let canvasRaised = Color(red: 0.075, green: 0.082, blue: 0.102)
  static let surface = Color.white.opacity(0.055)
  static let surfaceHover = Color.white.opacity(0.085)
  static let line = Color.white.opacity(0.11)
  static let text = Color(red: 0.96, green: 0.95, blue: 0.93)
  static let muted = Color(red: 0.64, green: 0.65, blue: 0.69)
  static let coral = Color(red: 0.91, green: 0.35, blue: 0.27)
  static let coralBright = Color(red: 1.0, green: 0.48, blue: 0.38)
  static let mint = Color(red: 0.34, green: 0.86, blue: 0.68)
  static let amber = Color(red: 0.95, green: 0.67, blue: 0.30)
}

struct StudioPanel<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(StudioColors.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(StudioColors.line, lineWidth: 1)
          )
      )
  }
}

struct StudioPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .frame(minHeight: 36)
      .background(
        LinearGradient(
          colors: [StudioColors.coralBright, StudioColors.coral],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
      )
      .opacity(configuration.isPressed ? 0.76 : 1)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}

struct StudioSecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 12, weight: .medium))
      .foregroundStyle(StudioColors.text)
      .padding(.horizontal, 13)
      .frame(minHeight: 32)
      .background(
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .fill(configuration.isPressed ? StudioColors.surfaceHover : StudioColors.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
              .stroke(StudioColors.line, lineWidth: 1)
          )
      )
  }
}

struct StudioStatusPill: View {
  let text: String
  let isActive: Bool
  let needsAttention: Bool

  var color: Color {
    if isActive { return StudioColors.mint }
    if needsAttention { return StudioColors.amber }
    return StudioColors.muted
  }

  var body: some View {
    HStack(spacing: 7) {
      Circle()
        .fill(color)
        .frame(width: 7, height: 7)
        .shadow(color: color.opacity(0.7), radius: isActive ? 5 : 0)
      Text(text)
        .font(.system(size: 11, weight: .semibold))
    }
    .foregroundStyle(color)
    .padding(.horizontal, 10)
    .frame(height: 26)
    .background(color.opacity(0.1), in: Capsule())
    .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
  }
}

extension View {
  func studioWindowBackground() -> some View {
    background(
      ZStack {
        StudioColors.canvas
        RadialGradient(
          colors: [StudioColors.coral.opacity(0.12), .clear],
          center: .topTrailing,
          startRadius: 0,
          endRadius: 520
        )
        LinearGradient(
          colors: [.clear, Color.black.opacity(0.22)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      .ignoresSafeArea()
    )
  }
}

import SwiftUI

/// ZoneLaunch visual tokens — teal accent from globe / meridian identity.
enum ZoneTheme {
  /// Primary brand accent (teal).
  static let accent = Color(red: 0.10, green: 0.58, blue: 0.62)

  /// Softer fill for selected rows and drop targets.
  static let accentSoft = accent.opacity(0.12)

  /// Stronger soft fill for active drop hover.
  static let accentSoftStrong = accent.opacity(0.18)

  static let cardRadius: CGFloat = 14
  static let sidebarWidth: CGFloat = 236
  static let contentPadding: CGFloat = 22
}

extension View {
  func zoneCardStyle() -> some View {
    self
      .padding(16)
      .background(
        .regularMaterial,
        in: RoundedRectangle(cornerRadius: ZoneTheme.cardRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: ZoneTheme.cardRadius, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
  }
}

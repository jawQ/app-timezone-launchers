import Foundation

/// User preference for app chrome appearance.
public enum AppearancePreference: String, Codable, CaseIterable, Sendable {
  case system
  case light
  case dark
}

/// App-level UI preferences (not launcher timezone configuration).
public struct AppSettings: Equatable, Sendable {
  public var appearance: AppearancePreference
  public var showInDock: Bool

  public init(
    appearance: AppearancePreference = .system,
    showInDock: Bool = true
  ) {
    self.appearance = appearance
    self.showInDock = showInDock
  }

  public static let `default` = AppSettings()
}

/// Persists ``AppSettings`` in `UserDefaults` (injectable for tests).
public struct AppSettingsRepository {
  public static let appearanceKey = "app.zonelaunch.settings.appearance"
  public static let showInDockKey = "app.zonelaunch.settings.showInDock"

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func load() -> AppSettings {
    let appearance: AppearancePreference
    if let raw = defaults.string(forKey: Self.appearanceKey),
      let parsed = AppearancePreference(rawValue: raw)
    {
      appearance = parsed
    } else {
      appearance = .system
    }

    let showInDock: Bool
    if defaults.object(forKey: Self.showInDockKey) == nil {
      showInDock = true
    } else {
      showInDock = defaults.bool(forKey: Self.showInDockKey)
    }

    return AppSettings(appearance: appearance, showInDock: showInDock)
  }

  public func save(_ settings: AppSettings) {
    defaults.set(settings.appearance.rawValue, forKey: Self.appearanceKey)
    defaults.set(settings.showInDock, forKey: Self.showInDockKey)
  }
}

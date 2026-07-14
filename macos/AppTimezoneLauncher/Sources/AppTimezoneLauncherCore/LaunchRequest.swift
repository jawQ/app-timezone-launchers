import AppKit
import Foundation

public struct LaunchRequest: Equatable {
  public var appURL: URL
  public var environment: [String: String]

  public init(
    app: ManagedApp,
    group: TimezoneGroup
  ) {
    appURL = URL(fileURLWithPath: app.appPath, isDirectory: true)
    environment = ["TZ": group.ianaTimezone]
  }
}

public enum AppLauncherError: Error, LocalizedError {
  case invalidTimezone(String)

  public var errorDescription: String? {
    switch self {
    case .invalidTimezone(let identifier):
      "Invalid IANA time zone: \(identifier)"
    }
  }
}

public struct AppLauncher {
  public init() {}

  public func launch(
    app: ManagedApp,
    in group: TimezoneGroup,
    completion: (@Sendable (String?) -> Void)? = nil
  ) throws {
    guard TimezoneIdentifierValidator.isValid(group.ianaTimezone) else {
      throw AppLauncherError.invalidTimezone(group.ianaTimezone)
    }

    let request = LaunchRequest(app: app, group: group)
    _ = try AppBundleParser.parse(request.appURL)

    let configuration = Self.openConfiguration(for: request)
    NSWorkspace.shared.openApplication(
      at: request.appURL,
      configuration: configuration
    ) { _, error in
      completion?(error?.localizedDescription)
    }
  }

  static func openConfiguration(for request: LaunchRequest) -> NSWorkspace.OpenConfiguration {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.environment = request.environment
    return configuration
  }
}

/// Policy for one-click “launch all apps in a time zone group”.
///
/// Batch launch is all-or-nothing: if any app is already running (login item,
/// manual open, etc.), those processes use the system time zone, so the batch
/// is refused until every listed app is quit.
public enum BatchLaunchPolicy {
  /// Sorted display names of apps that are currently running and therefore
  /// block batch launch. Empty means every app may be launched together.
  public static func runningAppsBlockingBatchLaunch(
    apps: [ManagedApp],
    isRunning: (ManagedApp) -> Bool
  ) -> [String] {
    apps
      .filter(isRunning)
      .map(\.displayName)
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }
}

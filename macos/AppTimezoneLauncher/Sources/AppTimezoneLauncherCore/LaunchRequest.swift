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

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.environment = request.environment
    configuration.createsNewApplicationInstance = true
    configuration.allowsRunningApplicationSubstitution = false
    NSWorkspace.shared.openApplication(
      at: request.appURL,
      configuration: configuration
    ) { _, error in
      completion?(error?.localizedDescription)
    }
  }
}

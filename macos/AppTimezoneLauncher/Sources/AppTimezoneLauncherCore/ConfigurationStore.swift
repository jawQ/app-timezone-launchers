import Foundation

public struct ConfigurationStore {
  public static let configPathEnvironmentKey = "APP_TIMEZONE_LAUNCHER_CONFIG_PATH"

  public let fileURL: URL

  public init(
    fileURL: URL? = nil,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) throws {
    if let fileURL {
      self.fileURL = fileURL
      return
    }
    if let configuredPath = environment[Self.configPathEnvironmentKey],
      !configuredPath.isEmpty
    {
      self.fileURL = URL(fileURLWithPath: configuredPath)
      return
    }

    let supportURL = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directoryURL = supportURL.appendingPathComponent("App Timezone Launcher")
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    self.fileURL = directoryURL.appendingPathComponent("config.json")
  }

  public func load() throws -> LauncherConfiguration {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return LauncherConfiguration()
    }

    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder.appTimezoneLauncher.decode(LauncherConfiguration.self, from: data)
  }

  public func save(_ configuration: LauncherConfiguration) throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try JSONEncoder.appTimezoneLauncher.encode(configuration)
    try data.write(to: fileURL, options: .atomic)
  }
}

extension JSONEncoder {
  fileprivate static var appTimezoneLauncher: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

extension JSONDecoder {
  fileprivate static var appTimezoneLauncher: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

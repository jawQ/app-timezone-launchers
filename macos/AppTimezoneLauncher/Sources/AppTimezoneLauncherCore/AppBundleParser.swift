import Foundation

public enum AppBundleParserError: Error, LocalizedError {
  case notAnAppBundle
  case missingInfoPlist
  case missingExecutableName
  case invalidExecutableName(String)
  case executableNotFound(String)

  public var errorDescription: String? {
    switch self {
    case .notAnAppBundle:
      "Drop a macOS .app bundle."
    case .missingInfoPlist:
      "The app bundle is missing Contents/Info.plist."
    case .missingExecutableName:
      "The app bundle does not declare CFBundleExecutable."
    case .invalidExecutableName(let name):
      "Invalid CFBundleExecutable value: \(name)"
    case .executableNotFound(let path):
      "Executable not found: \(path)"
    }
  }
}

public enum AppBundleParser {
  public static func parse(_ appURL: URL) throws -> ManagedApp {
    guard appURL.pathExtension == "app" else {
      throw AppBundleParserError.notAnAppBundle
    }

    let infoPlistURL =
      appURL
      .appendingPathComponent("Contents")
      .appendingPathComponent("Info.plist")
    guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
      throw AppBundleParserError.missingInfoPlist
    }

    let data = try Data(contentsOf: infoPlistURL)
    let propertyList = try PropertyListSerialization.propertyList(
      from: data,
      options: [],
      format: nil
    )
    let info = propertyList as? [String: Any] ?? [:]

    guard let executableName = info["CFBundleExecutable"] as? String,
      !executableName.isEmpty
    else {
      throw AppBundleParserError.missingExecutableName
    }
    guard executableName != ".",
      executableName != "..",
      !executableName.contains("/")
    else {
      throw AppBundleParserError.invalidExecutableName(executableName)
    }

    let executableURL =
      appURL
      .appendingPathComponent("Contents")
      .appendingPathComponent("MacOS")
      .appendingPathComponent(executableName)
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      throw AppBundleParserError.executableNotFound(executableURL.path)
    }

    let displayName =
      info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String
      ?? appURL.deletingPathExtension().lastPathComponent
    let bundleIdentifier = info["CFBundleIdentifier"] as? String ?? ""

    return ManagedApp(
      displayName: displayName,
      bundleIdentifier: bundleIdentifier,
      appPath: appURL.path,
      executablePath: executableURL.path
    )
  }
}

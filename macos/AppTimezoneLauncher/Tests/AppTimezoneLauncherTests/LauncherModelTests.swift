import Foundation
import Testing
import UniformTypeIdentifiers

@testable import AppTimezoneLauncherCore

@Test
func appBundleParsingReadsBundleMetadataAndExecutablePath() throws {
  let bundleURL = try makeFakeAppBundle(
    name: "Demo",
    executableName: "DemoExecutable",
    bundleIdentifier: "com.example.demo"
  )
  defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }

  let parsed = try AppBundleParser.parse(bundleURL)

  #expect(parsed.displayName == "Demo")
  #expect(parsed.bundleIdentifier == "com.example.demo")
  #expect(parsed.appPath == bundleURL.path)
  #expect(parsed.executablePath.hasSuffix("/Demo.app/Contents/MacOS/DemoExecutable"))
}

@Test
func appBundleParserRejectsExecutableNamesWithPathComponents() throws {
  let bundleURL = try makeFakeAppBundle(
    name: "Unsafe",
    executableName: "../../outside-bundle",
    bundleIdentifier: "com.example.unsafe"
  )
  defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }

  #expect(throws: (any Error).self) {
    try AppBundleParser.parse(bundleURL)
  }
}

@Test
func sameAppCanBeAssignedToMultipleTimezoneGroups() throws {
  let app = ManagedApp(
    displayName: "WeChat",
    bundleIdentifier: "com.tencent.xinWeChat",
    appPath: "/Applications/WeChat.app",
    executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
  )
  let shanghai = TimezoneGroup(name: "China Mainland", ianaTimezone: "Asia/Shanghai")
  let sanFrancisco = TimezoneGroup(name: "San Francisco", ianaTimezone: "America/Los_Angeles")

  var configuration = LauncherConfiguration(
    groups: [shanghai, sanFrancisco],
    apps: [app],
    entries: []
  )
  configuration.add(appID: app.id, to: shanghai.id)
  configuration.add(appID: app.id, to: sanFrancisco.id)

  #expect(configuration.entries.count == 2)
  #expect(Set(configuration.entries.map(\.groupID)) == [shanghai.id, sanFrancisco.id])
  #expect(Set(configuration.entries.map(\.managedAppID)) == [app.id])
}

@Test
func removeEntryDropsOnlyThatTimezoneRecordAndPrunesUnusedApps() {
  let app = ManagedApp(
    displayName: "WeChat",
    bundleIdentifier: "com.tencent.xinWeChat",
    appPath: "/Applications/WeChat.app",
    executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
  )
  let shanghai = TimezoneGroup(name: "China Mainland", ianaTimezone: "Asia/Shanghai")
  let singapore = TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore")
  var configuration = LauncherConfiguration(
    groups: [shanghai, singapore],
    apps: [app],
    entries: []
  )
  configuration.add(appID: app.id, to: shanghai.id)
  configuration.add(appID: app.id, to: singapore.id)

  let shanghaiEntry = configuration.entries.first { $0.groupID == shanghai.id }!
  configuration.removeEntry(id: shanghaiEntry.id)

  #expect(configuration.entries.count == 1)
  #expect(configuration.entries.first?.groupID == singapore.id)
  #expect(configuration.apps.count == 1)

  let singaporeEntry = configuration.entries.first!
  configuration.removeEntry(id: singaporeEntry.id)

  #expect(configuration.entries.isEmpty)
  #expect(configuration.apps.isEmpty)
}

@Test
func updateGroupChangesNameAndIANAWhilePreservingIdentityAndEntries() {
  let app = ManagedApp(
    displayName: "WeChat",
    bundleIdentifier: "com.tencent.xinWeChat",
    appPath: "/Applications/WeChat.app",
    executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
  )
  let sanFrancisco = TimezoneGroup(
    name: "San Francisco",
    ianaTimezone: "America/Los_Angeles",
    sortOrder: 3
  )
  var configuration = LauncherConfiguration(
    groups: [sanFrancisco],
    apps: [app],
    entries: []
  )
  configuration.add(appID: app.id, to: sanFrancisco.id)
  let entryID = configuration.entries.first!.id

  let updated = configuration.updateGroup(
    id: sanFrancisco.id,
    name: "Singapore",
    ianaTimezone: "Asia/Singapore"
  )

  #expect(updated)
  #expect(configuration.groups.count == 1)
  let group = configuration.groups[0]
  #expect(group.id == sanFrancisco.id)
  #expect(group.name == "Singapore")
  #expect(group.ianaTimezone == "Asia/Singapore")
  #expect(group.sortOrder == 3)
  #expect(configuration.entries.map(\.id) == [entryID])
  #expect(configuration.entries.first?.groupID == sanFrancisco.id)
  #expect(configuration.apps.map(\.id) == [app.id])
}

@Test
func updateGroupReturnsFalseForUnknownGroupID() {
  let group = TimezoneGroup(name: "Tokyo", ianaTimezone: "Asia/Tokyo")
  var configuration = LauncherConfiguration(groups: [group])

  let updated = configuration.updateGroup(
    id: UUID(),
    name: "Singapore",
    ianaTimezone: "Asia/Singapore"
  )

  #expect(!updated)
  #expect(configuration.groups == [group])
}

@Test
func removeGroupDeletesTimezoneAndItsEntriesOnly() {
  let wechat = ManagedApp(
    displayName: "WeChat",
    bundleIdentifier: "com.tencent.xinWeChat",
    appPath: "/Applications/WeChat.app",
    executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
  )
  let lark = ManagedApp(
    displayName: "Lark",
    bundleIdentifier: "com.bytedance.macos.feishu",
    appPath: "/Applications/Lark.app",
    executablePath: "/Applications/Lark.app/Contents/MacOS/Feishu"
  )
  let shanghai = TimezoneGroup(name: "China Mainland", ianaTimezone: "Asia/Shanghai")
  let singapore = TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore")
  var configuration = LauncherConfiguration(
    groups: [shanghai, singapore],
    apps: [wechat, lark],
    entries: []
  )
  configuration.add(appID: wechat.id, to: shanghai.id)
  configuration.add(appID: lark.id, to: singapore.id)

  configuration.removeGroup(id: shanghai.id)

  #expect(configuration.groups.map(\.id) == [singapore.id])
  #expect(configuration.entries.count == 1)
  #expect(configuration.entries.first?.managedAppID == lark.id)
  #expect(configuration.apps.map(\.id) == [lark.id])
}

@Test
func redroppingMovedAppRefreshesItsStoredPath() {
  let group = TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore")
  let original = ManagedApp(
    displayName: "Demo",
    bundleIdentifier: "com.example.demo",
    appPath: "/Applications/Demo.app",
    executablePath: "/Applications/Demo.app/Contents/MacOS/Demo"
  )
  let moved = ManagedApp(
    displayName: "Demo",
    bundleIdentifier: "com.example.demo",
    appPath: "/Users/example/Applications/Demo.app",
    executablePath: "/Users/example/Applications/Demo.app/Contents/MacOS/Demo"
  )
  var configuration = LauncherConfiguration(groups: [group])

  configuration.upsert(app: original, into: group.id)
  configuration.upsert(app: moved, into: group.id)

  #expect(configuration.apps.count == 1)
  #expect(configuration.apps.first?.appPath == moved.appPath)
  #expect(configuration.apps.first?.executablePath == moved.executablePath)
  #expect(configuration.entries.count == 1)
}

@Test
func timezoneIdentifierValidationAcceptsIANAValuesAndRejectsUnknownValues() {
  #expect(TimezoneIdentifierValidator.isValid("Asia/Shanghai"))
  #expect(TimezoneIdentifierValidator.isValid("America/Los_Angeles"))
  #expect(!TimezoneIdentifierValidator.isValid("Mars/Olympus_Mons"))
  #expect(!TimezoneIdentifierValidator.isValid(""))
}

@Test
func launchRequestContainsOnlyTheSelectedTimezone() throws {
  let app = ManagedApp(
    displayName: "Lark",
    bundleIdentifier: "com.bytedance.macos.feishu",
    appPath: "/Applications/Lark.app",
    executablePath: "/Applications/Lark.app/Contents/MacOS/Feishu"
  )
  let group = TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore")
  let parentTimezone = ProcessInfo.processInfo.environment["TZ"]

  let request = LaunchRequest(app: app, group: group)

  #expect(request.appURL.path == app.appPath)
  #expect(request.environment == ["TZ": "Asia/Singapore"])
  #expect(ProcessInfo.processInfo.environment["TZ"] == parentTimezone)
}

@Test
func workspaceOpenConfigurationPreservesDefaultApplicationInstanceBehavior() {
  let app = ManagedApp(
    displayName: "CodexBar",
    bundleIdentifier: "com.steipete.codexbar",
    appPath: "/Applications/CodexBar.app",
    executablePath: "/Applications/CodexBar.app/Contents/MacOS/CodexBar"
  )
  let group = TimezoneGroup(name: "China Mainland", ianaTimezone: "Asia/Shanghai")
  let request = LaunchRequest(app: app, group: group)

  let configuration = AppLauncher.openConfiguration(for: request)

  #expect(configuration.environment == ["TZ": "Asia/Shanghai"])
  #expect(!configuration.createsNewApplicationInstance)
  #expect(configuration.allowsRunningApplicationSubstitution)
}

@Test
func batchLaunchPolicyAllowsWhenNoAppsAreRunning() {
  let apps = [
    ManagedApp(
      displayName: "Lark",
      bundleIdentifier: "com.electron.lark",
      appPath: "/Applications/Lark.app",
      executablePath: "/Applications/Lark.app/Contents/MacOS/Lark"
    ),
    ManagedApp(
      displayName: "WeChat",
      bundleIdentifier: "com.tencent.xinWeChat",
      appPath: "/Applications/WeChat.app",
      executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
    ),
  ]

  let blocked = BatchLaunchPolicy.runningAppsBlockingBatchLaunch(apps: apps) { _ in false }

  #expect(blocked.isEmpty)
}

@Test
func batchLaunchPolicyBlocksWhenAnyAppIsRunningAndSortsNames() {
  let apps = [
    ManagedApp(
      displayName: "WeChat",
      bundleIdentifier: "com.tencent.xinWeChat",
      appPath: "/Applications/WeChat.app",
      executablePath: "/Applications/WeChat.app/Contents/MacOS/WeChat"
    ),
    ManagedApp(
      displayName: "CodexBar",
      bundleIdentifier: "com.steipete.codexbar",
      appPath: "/Applications/CodexBar.app",
      executablePath: "/Applications/CodexBar.app/Contents/MacOS/CodexBar"
    ),
    ManagedApp(
      displayName: "Lark",
      bundleIdentifier: "com.electron.lark",
      appPath: "/Applications/Lark.app",
      executablePath: "/Applications/Lark.app/Contents/MacOS/Lark"
    ),
  ]

  let blocked = BatchLaunchPolicy.runningAppsBlockingBatchLaunch(apps: apps) { app in
    app.displayName == "WeChat" || app.displayName == "CodexBar"
  }

  #expect(blocked == ["CodexBar", "WeChat"])
}

@Test
func workspaceAppLauncherUsesTheBundlePathAndInjectsTimezone() async throws {
  let temporaryDirectory = try makeTemporaryDirectory()
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  let outputURL = temporaryDirectory.appendingPathComponent("timezone.txt")
  let script = """
    #!/bin/sh
    /usr/bin/printenv TZ > \(shellQuoted(outputURL.path))
    """
  let bundleURL = try makeFakeAppBundle(
    name: "Environment Probe",
    executableName: "EnvironmentProbe",
    bundleIdentifier: "com.example.environment-probe.\(UUID().uuidString)",
    executableContents: script
  )
  defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }

  let parentTimezone = ProcessInfo.processInfo.environment["TZ"]
  var app = try AppBundleParser.parse(bundleURL)
  app.executablePath = "/path/that/must/not/be-used"
  let group = TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore")

  let launchError = try await withCheckedThrowingContinuation { continuation in
    do {
      try AppLauncher().launch(app: app, in: group) { errorMessage in
        continuation.resume(returning: errorMessage)
      }
    } catch {
      continuation.resume(throwing: error)
    }
  }
  #expect(launchError == nil)
  try waitForNonemptyFile(at: outputURL)

  let childTimezone = try String(contentsOf: outputURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  #expect(childTimezone == "Asia/Singapore")
  #expect(ProcessInfo.processInfo.environment["TZ"] == parentTimezone)
}

@Test
func configurationStoreRoundTripsUsingAnExplicitTemporaryLocation() throws {
  let temporaryDirectory = try makeTemporaryDirectory()
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  let store = try ConfigurationStore(
    fileURL: temporaryDirectory.appendingPathComponent("nested/config.json")
  )
  let group = TimezoneGroup(name: "Tokyo", ianaTimezone: "Asia/Tokyo")
  let app = ManagedApp(
    displayName: "Demo",
    bundleIdentifier: "com.example.demo",
    appPath: "/Applications/Demo.app",
    executablePath: "/Applications/Demo.app/Contents/MacOS/Demo",
    createdAt: Date(timeIntervalSince1970: 1_700_000_000)
  )
  var configuration = LauncherConfiguration(groups: [group], apps: [app])
  configuration.add(appID: app.id, to: group.id)

  try store.save(configuration)

  #expect(try store.load() == configuration)
}

@Test
func configurationStoreUsesEnvironmentConfigPathOverride() throws {
  let temporaryDirectory = try makeTemporaryDirectory()
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  let expectedURL = temporaryDirectory.appendingPathComponent("isolated/config.json")

  let store = try ConfigurationStore(
    environment: ["APP_TIMEZONE_LAUNCHER_CONFIG_PATH": expectedURL.path]
  )
  let configuration = LauncherConfiguration()

  try store.save(configuration)

  #expect(store.fileURL == expectedURL)
  #expect(FileManager.default.fileExists(atPath: expectedURL.path))
  #expect(try store.load() == configuration)
}

@Test
func appSettingsDefaultsMatchProductExpectations() {
  let settings = AppSettings.default
  #expect(settings.appearance == .system)
  #expect(settings.showInDock == true)
}

@Test
func appearancePreferenceRawValuesAreStable() {
  #expect(AppearancePreference.system.rawValue == "system")
  #expect(AppearancePreference.light.rawValue == "light")
  #expect(AppearancePreference.dark.rawValue == "dark")
  #expect(AppearancePreference(rawValue: "dark") == .dark)
  #expect(AppearancePreference(rawValue: "unknown") == nil)
}

@Test
func appSettingsRepositoryRoundTripsThroughUserDefaults() {
  let suiteName = "app.zonelaunch.tests.settings.\(UUID().uuidString)"
  guard let defaults = UserDefaults(suiteName: suiteName) else {
    Issue.record("Failed to create isolated UserDefaults suite")
    return
  }
  defer { defaults.removePersistentDomain(forName: suiteName) }

  let repository = AppSettingsRepository(defaults: defaults)
  #expect(repository.load() == AppSettings.default)

  let updated = AppSettings(appearance: .dark, showInDock: false)
  repository.save(updated)
  #expect(repository.load() == updated)

  repository.save(AppSettings(appearance: .light, showInDock: true))
  #expect(repository.load() == AppSettings(appearance: .light, showInDock: true))
}

@Test
func appSettingsRepositoryFallsBackWhenStoredValuesAreMissingOrInvalid() {
  let suiteName = "app.zonelaunch.tests.settings.fallback.\(UUID().uuidString)"
  guard let defaults = UserDefaults(suiteName: suiteName) else {
    Issue.record("Failed to create isolated UserDefaults suite")
    return
  }
  defer { defaults.removePersistentDomain(forName: suiteName) }

  defaults.set("not-a-mode", forKey: AppSettingsRepository.appearanceKey)
  let repository = AppSettingsRepository(defaults: defaults)
  let loaded = repository.load()
  #expect(loaded.appearance == .system)
  #expect(loaded.showInDock == true)
}

@Test
@MainActor
func droppedAppLoaderProcessesEveryFileProvider() async {
  let urls = [
    URL(fileURLWithPath: "/Applications/Lark.app"),
    URL(fileURLWithPath: "/Applications/WeChat.app"),
  ]
  let providers = urls.map(makeFileURLProvider)
  let receivedURLs: [URL] = await withCheckedContinuation { continuation in
    var received: [URL] = []
    let accepted = DroppedAppLoader.load(from: providers) { url in
      received.append(url)
      if received.count == urls.count {
        continuation.resume(returning: received)
      }
    }
    #expect(accepted)
  }

  #expect(Set(receivedURLs) == Set(urls))
}

private func makeFakeAppBundle(
  name: String,
  executableName: String,
  bundleIdentifier: String,
  executableContents: String = "#!/bin/sh\nexit 0\n"
) throws -> URL {
  let parent = try makeTemporaryDirectory()
  let root =
    parent
    .appendingPathComponent(name)
    .appendingPathExtension("app")
  let contents = root.appendingPathComponent("Contents")
  let macOS = contents.appendingPathComponent("MacOS")
  try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)

  let executable = macOS.appendingPathComponent(executableName)
  try executableContents.write(to: executable, atomically: true, encoding: .utf8)
  try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

  let info: [String: Any] = [
    "CFBundleName": name,
    "CFBundleIdentifier": bundleIdentifier,
    "CFBundleExecutable": executableName,
    "CFBundlePackageType": "APPL",
    "LSUIElement": true,
  ]
  let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
  try plist.write(to: contents.appendingPathComponent("Info.plist"))

  return root
}

private func makeTemporaryDirectory() throws -> URL {
  let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  return directory
}

private func waitForNonemptyFile(at url: URL) throws {
  let deadline = Date().addingTimeInterval(2)
  while Date() < deadline {
    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
      let size = attributes[.size] as? NSNumber,
      size.intValue > 0
    {
      return
    }
    Thread.sleep(forTimeInterval: 0.01)
  }
  throw TestSupportError.timedOutWaitingForFile(url.path)
}

private func shellQuoted(_ value: String) -> String {
  "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

private func makeFileURLProvider(_ url: URL) -> NSItemProvider {
  let provider = NSItemProvider()
  provider.registerDataRepresentation(
    forTypeIdentifier: UTType.fileURL.identifier,
    visibility: .all
  ) { completion in
    completion(url.dataRepresentation, nil)
    return nil
  }
  return provider
}

private enum TestSupportError: Error {
  case timedOutWaitingForFile(String)
}

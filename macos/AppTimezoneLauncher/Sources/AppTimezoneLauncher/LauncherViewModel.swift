import AppKit
import AppTimezoneLauncherCore
import Foundation
import UniformTypeIdentifiers

@MainActor
final class LauncherViewModel: ObservableObject {
  @Published var configuration: LauncherConfiguration
  @Published var selectedGroupID: UUID?
  @Published var alertMessage: String?

  private let launcher = AppLauncher()
  private var store: ConfigurationStore?

  var sortedGroups: [TimezoneGroup] {
    configuration.groups.sorted {
      if $0.sortOrder == $1.sortOrder {
        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }
      return $0.sortOrder < $1.sortOrder
    }
  }

  var selectedGroup: TimezoneGroup? {
    guard let selectedGroupID else { return sortedGroups.first }
    return configuration.groups.first { $0.id == selectedGroupID }
  }

  var selectedEntries: [(LauncherEntry, ManagedApp)] {
    guard let group = selectedGroup else { return [] }
    return entries(for: group).map { ($0.entry, $0.app) }
  }

  init() {
    do {
      let store = try ConfigurationStore()
      self.store = store
      self.configuration = try store.load()
    } catch {
      self.store = nil
      self.configuration = LauncherConfiguration()
      self.alertMessage = error.localizedDescription
    }

    self.selectedGroupID = sortedGroups.first?.id
  }

  func addTimezoneGroup(name: String, ianaTimezone: String) {
    guard let trimmed = validatedGroupFields(name: name, ianaTimezone: ianaTimezone) else {
      return
    }

    let nextSortOrder = (configuration.groups.map(\.sortOrder).max() ?? -1) + 1
    let group = TimezoneGroup(
      name: trimmed.name,
      ianaTimezone: trimmed.ianaTimezone,
      sortOrder: nextSortOrder
    )
    configuration.groups.append(group)
    selectedGroupID = group.id
    save()
  }

  /// Renames a group and/or changes its IANA time zone.
  /// Existing apps in the group stay assigned; future launches use the new TZ.
  func updateTimezoneGroup(_ group: TimezoneGroup, name: String, ianaTimezone: String) {
    guard let trimmed = validatedGroupFields(name: name, ianaTimezone: ianaTimezone) else {
      return
    }
    let didUpdate = configuration.updateGroup(
      id: group.id,
      name: trimmed.name,
      ianaTimezone: trimmed.ianaTimezone
    )
    guard didUpdate else {
      alertMessage = "That time zone group no longer exists."
      return
    }
    selectedGroupID = group.id
    save()
  }

  private func validatedGroupFields(
    name: String,
    ianaTimezone: String
  ) -> (name: String, ianaTimezone: String)? {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTimezone = ianaTimezone.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty, !trimmedTimezone.isEmpty else {
      alertMessage = "Enter a group name and IANA time zone."
      return nil
    }
    guard TimezoneIdentifierValidator.isValid(trimmedTimezone) else {
      alertMessage = "Enter a valid IANA time zone, such as Asia/Shanghai."
      return nil
    }
    return (trimmedName, trimmedTimezone)
  }

  func addApp(from url: URL) {
    guard let group = selectedGroup else { return }

    do {
      let app = try AppBundleParser.parse(url)
      configuration.upsert(app: app, into: group.id)
      save()
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  /// Opens a file picker starting at `/Applications` so users can choose `.app`
  /// bundles without knowing how to drag from Finder.
  func presentAppPicker() {
    guard selectedGroup != nil else { return }

    let panel = Self.makeAppOpenPanel()
    let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
      guard response == .OK, let self else { return }
      for url in panel.urls {
        self.addApp(from: url)
      }
    }

    if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
      panel.beginSheetModal(for: window, completionHandler: finish)
    } else {
      finish(panel.runModal())
    }
  }

  /// Shared panel setup for the app chooser (starts in `/Applications`).
  static func makeAppOpenPanel() -> NSOpenPanel {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = true
    panel.canCreateDirectories = false
    panel.treatsFilePackagesAsDirectories = false
    panel.allowedContentTypes = [.application]
    panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
    panel.title = "Choose Apps"
    panel.message = "Select apps to launch with the current time zone."
    panel.prompt = "Add"
    return panel
  }

  func launch(entry: LauncherEntry, app: ManagedApp) {
    guard let group = configuration.group(for: entry) else { return }

    if isRunning(app: app) {
      alertMessage =
        "\(app.displayName) is already running. Quit it first, then launch again to apply \(group.ianaTimezone)."
      return
    }

    do {
      try launcher.launch(app: app, in: group) { [weak self] errorMessage in
        guard let errorMessage else { return }
        Task { @MainActor in
          self?.alertMessage = errorMessage
        }
      }
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  /// Launches every app in the group only when **none** are already running.
  /// Partially running groups are refused so system-timezone instances (login
  /// items / manual opens) are not mixed with TZ-injected launches.
  func launchAll(in group: TimezoneGroup) {
    let pairs = entries(for: group)
    guard !pairs.isEmpty else { return }

    let runningNames = BatchLaunchPolicy.runningAppsBlockingBatchLaunch(
      apps: pairs.map(\.app),
      isRunning: isRunning(app:)
    )

    if !runningNames.isEmpty {
      let listed = runningNames.joined(separator: ", ")
      alertMessage =
        "Cannot launch all apps in “\(group.name)”. Quit these first so the time zone can be applied: \(listed)."
      return
    }

    for pair in pairs {
      do {
        try launcher.launch(app: pair.app, in: group) { [weak self] errorMessage in
          guard let errorMessage else { return }
          Task { @MainActor in
            self?.alertMessage = errorMessage
          }
        }
      } catch {
        alertMessage = error.localizedDescription
        return
      }
    }
  }

  /// Sorted (entry, app) pairs for a group — same order as the main panel grid.
  func entries(for group: TimezoneGroup) -> [(entry: LauncherEntry, app: ManagedApp)] {
    configuration
      .entries(for: group.id)
      .compactMap { entry in
        guard let app = configuration.app(for: entry) else { return nil }
        return (entry, app)
      }
      .sorted {
        $0.app.displayName.localizedCaseInsensitiveCompare($1.app.displayName)
          == .orderedAscending
      }
  }

  func remove(entry: LauncherEntry) {
    configuration.removeEntry(id: entry.id)
    save()
  }

  func removeTimezoneGroup(_ group: TimezoneGroup) {
    let wasSelected = selectedGroupID == group.id
    configuration.removeGroup(id: group.id)
    if wasSelected {
      selectedGroupID = sortedGroups.first?.id
    }
    save()
  }

  func removeAppEverywhere(_ app: ManagedApp) {
    configuration.removeAppEverywhere(id: app.id)
    save()
  }

  func revealInFinder(_ app: ManagedApp) {
    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.appPath)])
  }

  private func isRunning(app: ManagedApp) -> Bool {
    guard !app.bundleIdentifier.isEmpty else { return false }
    return !NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
      .isEmpty
  }

  private func save() {
    do {
      try store?.save(configuration)
    } catch {
      alertMessage = error.localizedDescription
    }
  }
}

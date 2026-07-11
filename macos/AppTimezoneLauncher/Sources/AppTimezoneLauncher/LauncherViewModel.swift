import AppKit
import AppTimezoneLauncherCore
import Foundation

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
    return
      configuration
      .entries(for: group.id)
      .compactMap { entry in
        guard let app = configuration.app(for: entry) else { return nil }
        return (entry, app)
      }
      .sorted {
        $0.1.displayName.localizedCaseInsensitiveCompare($1.1.displayName) == .orderedAscending
      }
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
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTimezone = ianaTimezone.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty, !trimmedTimezone.isEmpty else {
      alertMessage = "Enter a group name and IANA time zone."
      return
    }
    guard TimezoneIdentifierValidator.isValid(trimmedTimezone) else {
      alertMessage = "Enter a valid IANA time zone, such as Asia/Shanghai."
      return
    }

    let nextSortOrder = (configuration.groups.map(\.sortOrder).max() ?? -1) + 1
    let group = TimezoneGroup(
      name: trimmedName,
      ianaTimezone: trimmedTimezone,
      sortOrder: nextSortOrder
    )
    configuration.groups.append(group)
    selectedGroupID = group.id
    save()
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

  func remove(entry: LauncherEntry) {
    configuration.entries.removeAll { $0.id == entry.id }
    save()
  }

  func removeAppEverywhere(_ app: ManagedApp) {
    configuration.entries.removeAll { $0.managedAppID == app.id }
    configuration.apps.removeAll { $0.id == app.id }
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

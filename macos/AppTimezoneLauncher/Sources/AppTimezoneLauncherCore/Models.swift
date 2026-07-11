import Foundation

public enum TimezoneIdentifierValidator {
  public static func isValid(_ identifier: String) -> Bool {
    !identifier.isEmpty && TimeZone(identifier: identifier) != nil
  }
}

public struct TimezoneGroup: Codable, Equatable, Identifiable, Hashable, Sendable {
  public var id: UUID
  public var name: String
  public var ianaTimezone: String
  public var sortOrder: Int

  public init(
    id: UUID = UUID(),
    name: String,
    ianaTimezone: String,
    sortOrder: Int = 0
  ) {
    self.id = id
    self.name = name
    self.ianaTimezone = ianaTimezone
    self.sortOrder = sortOrder
  }
}

public struct ManagedApp: Codable, Equatable, Identifiable, Hashable, Sendable {
  public var id: UUID
  public var displayName: String
  public var bundleIdentifier: String
  public var appPath: String
  public var executablePath: String
  public var createdAt: Date

  public init(
    id: UUID = UUID(),
    displayName: String,
    bundleIdentifier: String,
    appPath: String,
    executablePath: String,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.displayName = displayName
    self.bundleIdentifier = bundleIdentifier
    self.appPath = appPath
    self.executablePath = executablePath
    self.createdAt = createdAt
  }
}

public struct LauncherEntry: Codable, Equatable, Identifiable, Hashable, Sendable {
  public var id: UUID
  public var groupID: UUID
  public var managedAppID: UUID
  public var customDisplayName: String?

  public init(
    id: UUID = UUID(),
    groupID: UUID,
    managedAppID: UUID,
    customDisplayName: String? = nil
  ) {
    self.id = id
    self.groupID = groupID
    self.managedAppID = managedAppID
    self.customDisplayName = customDisplayName
  }
}

public struct LauncherConfiguration: Codable, Equatable, Sendable {
  public var groups: [TimezoneGroup]
  public var apps: [ManagedApp]
  public var entries: [LauncherEntry]

  public init(
    groups: [TimezoneGroup] = Self.defaultGroups,
    apps: [ManagedApp] = [],
    entries: [LauncherEntry] = []
  ) {
    self.groups = groups
    self.apps = apps
    self.entries = entries
  }

  public static let defaultGroups: [TimezoneGroup] = [
    TimezoneGroup(name: "China Mainland", ianaTimezone: "Asia/Shanghai", sortOrder: 0),
    TimezoneGroup(name: "San Francisco", ianaTimezone: "America/Los_Angeles", sortOrder: 1),
    TimezoneGroup(name: "Singapore", ianaTimezone: "Asia/Singapore", sortOrder: 2),
  ]

  public mutating func add(appID: UUID, to groupID: UUID) {
    guard apps.contains(where: { $0.id == appID }),
      groups.contains(where: { $0.id == groupID })
    else {
      return
    }

    let alreadyExists = entries.contains {
      $0.managedAppID == appID && $0.groupID == groupID
    }
    guard !alreadyExists else {
      return
    }

    entries.append(LauncherEntry(groupID: groupID, managedAppID: appID))
  }

  public mutating func upsert(app: ManagedApp, into groupID: UUID) {
    let existingIndex = apps.firstIndex { existingApp in
      existingApp.appPath == app.appPath
        || (!app.bundleIdentifier.isEmpty && existingApp.bundleIdentifier == app.bundleIdentifier)
    }

    if let existingIndex {
      let existingID = apps[existingIndex].id
      apps[existingIndex].displayName = app.displayName
      apps[existingIndex].bundleIdentifier = app.bundleIdentifier
      apps[existingIndex].appPath = app.appPath
      apps[existingIndex].executablePath = app.executablePath
      add(appID: existingID, to: groupID)
    } else {
      apps.append(app)
      add(appID: app.id, to: groupID)
    }
  }

  public func app(for entry: LauncherEntry) -> ManagedApp? {
    apps.first { $0.id == entry.managedAppID }
  }

  public func group(for entry: LauncherEntry) -> TimezoneGroup? {
    groups.first { $0.id == entry.groupID }
  }

  public func entries(for groupID: UUID) -> [LauncherEntry] {
    entries.filter { $0.groupID == groupID }
  }

  /// Removes a single launcher entry from its time zone group.
  /// Does not uninstall the macOS app; only drops the ZoneLaunch record.
  /// If the managed app is no longer referenced by any entry, it is pruned.
  public mutating func removeEntry(id: UUID) {
    guard entries.contains(where: { $0.id == id }) else { return }
    entries.removeAll { $0.id == id }
    pruneOrphanedApps()
  }

  /// Updates a time zone group's display name and IANA identifier.
  /// Keeps the group id, sort order, and all app entries under that group.
  /// Returns false when the group is missing.
  @discardableResult
  public mutating func updateGroup(id: UUID, name: String, ianaTimezone: String) -> Bool {
    guard let index = groups.firstIndex(where: { $0.id == id }) else { return false }
    groups[index].name = name
    groups[index].ianaTimezone = ianaTimezone
    return true
  }

  /// Removes a time zone group and every entry assigned to it.
  /// Managed apps that become unreferenced are pruned from configuration.
  public mutating func removeGroup(id: UUID) {
    guard groups.contains(where: { $0.id == id }) else { return }
    entries.removeAll { $0.groupID == id }
    groups.removeAll { $0.id == id }
    pruneOrphanedApps()
  }

  /// Removes every entry for an app and the managed app record itself.
  public mutating func removeAppEverywhere(id: UUID) {
    entries.removeAll { $0.managedAppID == id }
    apps.removeAll { $0.id == id }
  }

  private mutating func pruneOrphanedApps() {
    let referencedIDs = Set(entries.map(\.managedAppID))
    apps.removeAll { !referencedIDs.contains($0.id) }
  }
}

import AppKit
import AppTimezoneLauncherCore
import Combine
import SwiftUI

struct ContentView: View {
  @StateObject private var model = LauncherViewModel()
  @EnvironmentObject private var appSettings: AppSettingsStore
  @EnvironmentObject private var updates: UpdateCoordinator
  @State private var timezoneSheet: TimezoneGroupSheetMode?
  @State private var groupPendingDeletion: TimezoneGroup?
  @State private var groupPendingLaunchAll: TimezoneGroup?
  @State private var isSettingsPresented = false
  @State private var isAboutPresented = false

  var body: some View {
    HStack(spacing: 0) {
      SidebarView(
        groups: model.sortedGroups,
        selectedGroupID: $model.selectedGroupID,
        onAddGroup: {
          timezoneSheet = .add
        },
        onEditGroup: { group in
          timezoneSheet = .edit(group)
        },
        onDeleteGroup: { group in
          groupPendingDeletion = group
        }
      )

      Rectangle()
        .fill(Color.primary.opacity(0.08))
        .frame(width: 1)

      MainPanelView(
        model: model,
        onEditGroup: { group in
          timezoneSheet = .edit(group)
        },
        onDeleteGroup: { group in
          groupPendingDeletion = group
        },
        onLaunchAll: { group in
          groupPendingLaunchAll = group
        }
      )
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      if updates.state.isVisible {
        ToolbarItem {
          UpdateToolbarButton(coordinator: updates)
        }
      }
      ToolbarItem {
        Button {
          timezoneSheet = .add
        } label: {
          Label("Add Time Zone", systemImage: "plus")
        }
        .help("Add a time zone group")
      }
      ToolbarItem {
        Button {
          presentAbout()
        } label: {
          Label("关于", systemImage: "info.circle")
        }
        .help("查看版本信息并手动检查更新")
      }
      ToolbarItem {
        Button {
          isSettingsPresented = true
        } label: {
          Label("设置", systemImage: "gearshape")
        }
        .help("打开设置")
      }
      ToolbarItem {
        Button {
          AppChromeController.shared.quit()
        } label: {
          Label("退出应用", systemImage: "power")
        }
        .help("完全退出 ZoneLaunch（菜单栏图标也会消失）")
        .accessibilityLabel("退出应用")
      }
    }
    .sheet(item: $timezoneSheet) { mode in
      AddTimezoneSheet(model: model, mode: mode)
    }
    .sheet(isPresented: $isSettingsPresented) {
      SettingsSheet(settings: appSettings)
    }
    .sheet(isPresented: $isAboutPresented) {
      AboutSheet(updates: updates)
    }
    .onAppear {
      updates.checkForUpdatesWhenMainWindowOpens()
      if AppChromeController.shared.consumePendingShowAbout() {
        presentAbout()
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: AppChromeController.mainWindowDidPresentNotification
      )
    ) { _ in
      updates.checkForUpdatesWhenMainWindowOpens()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: AppChromeController.showAboutNotification)
    ) { _ in
      _ = AppChromeController.shared.consumePendingShowAbout()
      presentAbout()
    }
    .alert(
      "ZoneLaunch",
      isPresented: Binding(
        get: { model.alertMessage != nil },
        set: { if !$0 { model.alertMessage = nil } }
      )
    ) {
      Button("OK") {
        model.alertMessage = nil
      }
    } message: {
      Text(model.alertMessage ?? "")
    }
    .alert(
      "更新失败",
      isPresented: Binding(
        get: { updates.errorMessage != nil },
        set: { if !$0 { updates.errorMessage = nil } }
      )
    ) {
      Button("取消", role: .cancel) {
        updates.errorMessage = nil
      }
      Button("重试") {
        updates.errorMessage = nil
        updates.installOrRetry()
      }
    } message: {
      Text(updates.errorMessage ?? "无法完成更新，请稍后重试。")
    }
    .alert(
      "Delete Time Zone?",
      isPresented: Binding(
        get: { groupPendingDeletion != nil },
        set: { if !$0 { groupPendingDeletion = nil } }
      ),
      presenting: groupPendingDeletion
    ) { group in
      Button("Cancel", role: .cancel) {
        groupPendingDeletion = nil
      }
      Button("Delete", role: .destructive) {
        model.removeTimezoneGroup(group)
        groupPendingDeletion = nil
      }
    } message: { group in
      let appCount = model.configuration.entries(for: group.id).count
      if appCount == 0 {
        Text("Delete “\(group.name)”? This only removes the group from ZoneLaunch.")
      } else {
        Text(
          "Delete “\(group.name)” and remove \(appCount) app record\(appCount == 1 ? "" : "s") from this group? Installed apps on your Mac are not affected."
        )
      }
    }
    .alert(
      "Launch All Apps?",
      isPresented: Binding(
        get: { groupPendingLaunchAll != nil },
        set: { if !$0 { groupPendingLaunchAll = nil } }
      ),
      presenting: groupPendingLaunchAll
    ) { group in
      Button("Cancel", role: .cancel) {
        groupPendingLaunchAll = nil
      }
      Button("Launch All") {
        model.launchAll(in: group)
        groupPendingLaunchAll = nil
      }
    } message: { group in
      let appCount = model.configuration.entries(for: group.id).count
      Text(
        "Launch \(appCount) app\(appCount == 1 ? "" : "s") in “\(group.name)” with \(group.ianaTimezone)? All apps in this group must be quit first so the time zone can be applied."
      )
    }
  }

  /// Presents About after dismissing other modal UI so only one sheet is attached.
  private func presentAbout() {
    timezoneSheet = nil
    groupPendingDeletion = nil
    groupPendingLaunchAll = nil

    if isSettingsPresented {
      isSettingsPresented = false
      // AppKit only allows one sheet; wait a turn after dismiss.
      DispatchQueue.main.async {
        isAboutPresented = true
      }
      return
    }

    isAboutPresented = true
  }
}

// MARK: - Sidebar

private struct SidebarView: View {
  let groups: [TimezoneGroup]
  @Binding var selectedGroupID: UUID?
  let onAddGroup: () -> Void
  let onEditGroup: (TimezoneGroup) -> Void
  let onDeleteGroup: (TimezoneGroup) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Image(systemName: "globe.badge.clock")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(ZoneTheme.accent)
        Text("Time Zones")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
          .tracking(0.4)
      }
      .padding(.horizontal, 16)
      .padding(.top, 18)
      .padding(.bottom, 10)

      List(selection: $selectedGroupID) {
        ForEach(groups) { group in
          SidebarRow(group: group, isSelected: selectedGroupID == group.id)
            .tag(group.id as UUID?)
            .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            .contextMenu {
              Button("Edit Time Zone") {
                onEditGroup(group)
              }
              Button("Delete Time Zone", role: .destructive) {
                onDeleteGroup(group)
              }
            }
        }
        .onDelete { indexSet in
          for index in indexSet {
            guard groups.indices.contains(index) else { continue }
            onDeleteGroup(groups[index])
          }
        }
      }
      .listStyle(.sidebar)
      .scrollContentBackground(.hidden)

      Divider()
        .opacity(0.5)

      Button {
        onAddGroup()
      } label: {
        Label("Add Time Zone", systemImage: "plus.circle.fill")
          .font(.system(size: 13, weight: .medium))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 4)
      }
      .buttonStyle(.plain)
      .foregroundStyle(ZoneTheme.accent)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .frame(width: ZoneTheme.sidebarWidth)
    .background(Color(nsColor: .controlBackgroundColor))
  }
}

private struct SidebarRow: View {
  let group: TimezoneGroup
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 1.5, style: .continuous)
        .fill(isSelected ? ZoneTheme.accent : Color.clear)
        .frame(width: 3, height: 28)

      VStack(alignment: .leading, spacing: 3) {
        Text(group.name)
          .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        HStack(spacing: 6) {
          Text(group.ianaTimezone)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(1)

          Text(TimezoneDisplay.utcOffsetLabel(for: group.ianaTimezone))
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(isSelected ? ZoneTheme.accent : .secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
              Capsule(style: .continuous)
                .fill(isSelected ? ZoneTheme.accentSoft : Color.primary.opacity(0.06))
            )
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 6)
    .padding(.trailing, 6)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(isSelected ? ZoneTheme.accentSoft : Color.clear)
    )
  }
}

// MARK: - Main panel

private struct MainPanelView: View {
  @ObservedObject var model: LauncherViewModel
  var onEditGroup: (TimezoneGroup) -> Void
  var onDeleteGroup: (TimezoneGroup) -> Void
  var onLaunchAll: (TimezoneGroup) -> Void

  var body: some View {
    VStack(spacing: 0) {
      if let group = model.selectedGroup {
        HeaderView(
          group: group,
          appCount: model.selectedEntries.count,
          onEditGroup: { onEditGroup(group) },
          onDeleteGroup: { onDeleteGroup(group) },
          onLaunchAll: { onLaunchAll(group) }
        )

        Rectangle()
          .fill(Color.primary.opacity(0.06))
          .frame(height: 1)

        if model.selectedEntries.isEmpty {
          DropZoneView(model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          AppGridView(model: model)
        }
      } else {
        ContentUnavailableView {
          Label("No Time Zone", systemImage: "clock.badge.questionmark")
        } description: {
          Text("Create a time zone group before adding apps.")
        } actions: {
          // Toolbar / sidebar already expose add; keep empty actions for balance.
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(ZoneTheme.accent, .secondary)
      }
    }
  }
}

private struct HeaderView: View {
  let group: TimezoneGroup
  let appCount: Int
  let onEditGroup: () -> Void
  let onDeleteGroup: () -> Void
  let onLaunchAll: () -> Void
  @State private var now = Date()

  private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(group.name)
          .font(.system(size: 20, weight: .semibold, design: .rounded))
        HStack(spacing: 8) {
          Image(systemName: "globe")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(ZoneTheme.accent)
          Text(group.ianaTimezone)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
          Text(TimezoneDisplay.utcOffsetLabel(for: group.ianaTimezone))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ZoneTheme.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule(style: .continuous).fill(ZoneTheme.accentSoft))
        }
      }

      Spacer(minLength: 12)

      Button(action: onLaunchAll) {
        Label("Launch All", systemImage: "play.fill")
          .font(.system(size: 13, weight: .semibold))
      }
      .buttonStyle(.borderedProminent)
      .tint(ZoneTheme.accent)
      .controlSize(.large)
      .disabled(appCount == 0)
      .help(
        appCount == 0
          ? "Add apps to this time zone before launching all"
          : "Launch every app in this time zone group"
      )
      .accessibilityLabel("Launch all apps in \(group.name)")

      VStack(alignment: .trailing, spacing: 4) {
        Text(TimezoneDisplay.currentTime(for: group.ianaTimezone, at: now))
          .font(.system(size: 28, weight: .medium, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(ZoneTheme.accent)
        Text(TimezoneDisplay.currentDate(for: group.ianaTimezone, at: now))
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Menu {
        Button("Edit Time Zone") {
          onEditGroup()
        }
        Button("Delete Time Zone", role: .destructive) {
          onDeleteGroup()
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)
      }
      .menuStyle(.borderlessButton)
      .frame(width: 28, height: 28)
      .help("Time zone actions")
    }
    .padding(.horizontal, ZoneTheme.contentPadding)
    .padding(.vertical, 16)
    .background(Color(nsColor: .windowBackgroundColor))
    .onReceive(timer) { value in
      now = value
    }
  }
}

// MARK: - Drop zone

private struct DropZoneView: View {
  @ObservedObject var model: LauncherViewModel
  @State private var isTargeted = false
  @State private var isHovered = false

  private var isHighlighted: Bool { isTargeted || isHovered }

  var body: some View {
    Button {
      model.presentAppPicker()
    } label: {
      VStack(spacing: 20) {
        ZStack {
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
              isHighlighted ? ZoneTheme.accentSoftStrong : ZoneTheme.accentSoft.opacity(0.45)
            )
            .frame(width: 168, height: 168)

          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
              isHighlighted ? ZoneTheme.accent : ZoneTheme.accent.opacity(0.35),
              style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 2, dash: [11, 8])
            )
            .frame(width: 168, height: 168)

          Image(
            systemName: isTargeted
              ? "plus.app.fill"
              : (isHovered ? "folder.badge.plus" : "square.and.arrow.down")
          )
          .font(.system(size: 52, weight: .light))
          .foregroundStyle(ZoneTheme.accent.opacity(isHighlighted ? 1 : 0.75))
          .symbolRenderingMode(.hierarchical)
        }
        .scaleEffect(isHighlighted ? 1.03 : 1)
        .animation(.easeOut(duration: 0.15), value: isHighlighted)

        VStack(spacing: 8) {
          Text("Drop your apps here")
            .font(.system(size: 26, weight: .medium, design: .rounded))
            .foregroundStyle(.primary.opacity(0.85))

          Text("Click to open Applications, or drag apps here.")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)

          Text("Apps will launch with this time zone injected.")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .background(
        isHighlighted
          ? ZoneTheme.accentSoft.opacity(0.5)
          : Color.clear
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
      handleDrop(providers)
    }
    .help("Click to choose apps from Applications, or drop .app files here")
    .accessibilityLabel("Add apps")
    .accessibilityHint("Opens the Applications folder so you can choose apps, or drop apps here")
  }

  private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
    DroppedAppLoader.load(from: providers) { url in
      model.addApp(from: url)
    }
  }
}

// MARK: - App grid

private struct AppGridView: View {
  @ObservedObject var model: LauncherViewModel
  @State private var isTargeted = false

  private let columns = [
    GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(model.selectedEntries, id: \.0.id) { entry, app in
          AppCardView(model: model, entry: entry, app: app)
        }

        AddAppCardView {
          model.presentAppPicker()
        }
      }
      .padding(ZoneTheme.contentPadding)
    }
    .background(isTargeted ? ZoneTheme.accentSoft : Color.clear)
    .animation(.easeOut(duration: 0.15), value: isTargeted)
    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
      handleDrop(providers)
    }
  }

  private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
    DroppedAppLoader.load(from: providers) { url in
      model.addApp(from: url)
    }
  }
}

private struct AddAppCardView: View {
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        Spacer(minLength: 0)

        Image(systemName: "plus.app")
          .font(.system(size: 28, weight: .light))
          .foregroundStyle(ZoneTheme.accent)
          .symbolRenderingMode(.hierarchical)

        Text("Add App")
          .font(.system(size: 14, weight: .semibold))

        Text("Browse Applications…")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, minHeight: ZoneTheme.appCardMinHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .zoneCardStyle()
    .overlay(
      RoundedRectangle(cornerRadius: ZoneTheme.cardRadius, style: .continuous)
        .strokeBorder(
          ZoneTheme.accent.opacity(isHovered ? 0.45 : 0.22),
          style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])
        )
    )
    .scaleEffect(isHovered ? 1.015 : 1)
    .animation(.easeOut(duration: 0.12), value: isHovered)
    .onHover { isHovered = $0 }
    .help("Choose apps from the Applications folder")
    .accessibilityLabel("Add app")
    .accessibilityHint("Opens the Applications folder so you can choose apps")
  }
}

private struct AppCardView: View {
  @ObservedObject var model: LauncherViewModel
  let entry: LauncherEntry
  let app: ManagedApp
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        Image(nsImage: NSWorkspace.shared.icon(forFile: app.appPath))
          .resizable()
          .interpolation(.high)
          .frame(width: 48, height: 48)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)

        VStack(alignment: .leading, spacing: 3) {
          Text(app.displayName)
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(1)
          Text(shortPath(app.appPath))
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Spacer(minLength: 4)

        Button {
          model.remove(entry: entry)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.35)
        .help("Remove from this time zone")
        .accessibilityLabel("Remove \(app.displayName) from this time zone")
      }

      Spacer(minLength: 0)

      Button {
        model.launch(entry: entry, app: app)
      } label: {
        Label("Launch", systemImage: "play.fill")
          .font(.system(size: 13, weight: .semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 2)
      }
      .buttonStyle(.borderedProminent)
      .tint(ZoneTheme.accent)
      .controlSize(.large)
    }
    .frame(maxWidth: .infinity, minHeight: ZoneTheme.appCardMinHeight, alignment: .top)
    .zoneCardStyle()
    .scaleEffect(isHovered ? 1.015 : 1)
    .animation(.easeOut(duration: 0.12), value: isHovered)
    .onHover { isHovered = $0 }
    .contextMenu {
      Button("Reveal in Finder") {
        model.revealInFinder(app)
      }
      Button("Remove from This Time Zone") {
        model.remove(entry: entry)
      }
      Divider()
      Button("Remove App Everywhere", role: .destructive) {
        model.removeAppEverywhere(app)
      }
    }
  }

  private func shortPath(_ path: String) -> String {
    path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
  }
}

// MARK: - Timezone display helpers

enum TimezoneDisplay {
  static func utcOffsetLabel(for iana: String, at date: Date = Date()) -> String {
    guard let tz = TimeZone(identifier: iana) else { return "UTC?" }
    let seconds = tz.secondsFromGMT(for: date)
    let hours = seconds / 3600
    let minutes = abs(seconds / 60) % 60
    if minutes == 0 {
      return String(format: "UTC%+d", hours)
    }
    return String(format: "UTC%+d:%02d", hours, minutes)
  }

  static func currentTime(for iana: String, at date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: iana) ?? .current
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }

  static func currentDate(for iana: String, at date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.timeZone = TimeZone(identifier: iana) ?? .current
    formatter.dateFormat = "EEE, MMM d"
    return formatter.string(from: date)
  }
}

import AppKit
import AppTimezoneLauncherCore
import SwiftUI

struct ContentView: View {
  @StateObject private var model = LauncherViewModel()
  @State private var showingAddTimezone = false

  var body: some View {
    HStack(spacing: 0) {
      SidebarView(
        groups: model.sortedGroups,
        selectedGroupID: $model.selectedGroupID,
        showingAddTimezone: $showingAddTimezone
      )

      Divider()

      MainPanelView(model: model)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      ToolbarItem {
        Button {
          showingAddTimezone = true
        } label: {
          Label("Add Time Zone", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showingAddTimezone) {
      AddTimezoneSheet(model: model)
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
  }
}

private struct SidebarView: View {
  let groups: [TimezoneGroup]
  @Binding var selectedGroupID: UUID?
  @Binding var showingAddTimezone: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Time Zones")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.top, 18)

      List(selection: $selectedGroupID) {
        ForEach(groups) { group in
          VStack(alignment: .leading, spacing: 3) {
            Text(group.name)
              .font(.system(size: 13, weight: .medium))
            Text(group.ianaTimezone)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
          .tag(group.id as UUID?)
        }
      }
      .listStyle(.sidebar)

      Button {
        showingAddTimezone = true
      } label: {
        Label("Add Time Zone", systemImage: "plus")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.borderless)
      .padding(.horizontal, 14)
      .padding(.bottom, 14)
    }
    .frame(width: 220)
    .background(Color(nsColor: .controlBackgroundColor))
  }
}

private struct MainPanelView: View {
  @ObservedObject var model: LauncherViewModel

  var body: some View {
    VStack(spacing: 0) {
      if let group = model.selectedGroup {
        HeaderView(group: group)

        if model.selectedEntries.isEmpty {
          DropZoneView(model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          AppGridView(model: model)
        }
      } else {
        ContentUnavailableView(
          "No Time Zone",
          systemImage: "clock.badge.questionmark",
          description: Text("Create a time zone group before adding apps.")
        )
      }
    }
  }
}

private struct HeaderView: View {
  let group: TimezoneGroup

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 3) {
        Text(group.name)
          .font(.title3.weight(.semibold))
        Text(group.ianaTimezone)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Label("Drop .app files anywhere below", systemImage: "arrow.down.app")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
    .background(Color(nsColor: .windowBackgroundColor))
  }
}

private struct DropZoneView: View {
  @ObservedObject var model: LauncherViewModel
  @State private var isTargeted = false

  var body: some View {
    VStack(spacing: 18) {
      ZStack {
        RoundedRectangle(cornerRadius: 24)
          .stroke(
            style: StrokeStyle(lineWidth: 4, dash: [12, 10])
          )
          .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.42))
          .frame(width: 170, height: 170)

        Image(systemName: "app")
          .font(.system(size: 64, weight: .light))
          .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.55))
      }

      Text("Drop your apps here")
        .font(.system(size: 34, weight: .light))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
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

private struct AppGridView: View {
  @ObservedObject var model: LauncherViewModel
  @State private var isTargeted = false

  private let columns = [
    GridItem(.adaptive(minimum: 210, maximum: 260), spacing: 16)
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(model.selectedEntries, id: \.0.id) { entry, app in
          AppCardView(model: model, entry: entry, app: app)
        }
      }
      .padding(24)
    }
    .background(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
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

private struct AppCardView: View {
  @ObservedObject var model: LauncherViewModel
  let entry: LauncherEntry
  let app: ManagedApp

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        Image(nsImage: NSWorkspace.shared.icon(forFile: app.appPath))
          .resizable()
          .frame(width: 44, height: 44)

        VStack(alignment: .leading, spacing: 3) {
          Text(app.displayName)
            .font(.headline)
            .lineLimit(1)
          Text(shortPath(app.appPath))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Button {
        model.launch(entry: entry, app: app)
      } label: {
        Label("Launch", systemImage: "play.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
    .padding(16)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
